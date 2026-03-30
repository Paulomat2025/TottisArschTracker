using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Timers;

namespace ArtTimeTracker.Core.Services;

public class ProcessWatcher : IDisposable
{
    private readonly System.Timers.Timer _pollTimer;
    private string? _lastDetectedFile;

    private static readonly string[] CspProcessNames = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
        ? new[] { "CLIPStudioPaint" }
        : new[] { "CLIP STUDIO PAINT", "CLIPStudioPaint" };

    public bool IsWatching { get; private set; }
    public string? CurrentFileName { get; private set; }

    /// <summary>Dateiname geändert (neuer Name, oder null wenn CSP geschlossen)</summary>
    public event Action<string?>? FileChanged;

    /// <summary>Status-Update für die UI</summary>
    public event Action<string>? StatusChanged;

    public ProcessWatcher(double pollIntervalMs = 3000)
    {
        _pollTimer = new System.Timers.Timer(pollIntervalMs);
        _pollTimer.Elapsed += (_, _) => Poll();
    }

    public void Start()
    {
        IsWatching = true;
        StatusChanged?.Invoke("Warte auf Clip Studio Paint...");
        _pollTimer.Start();
    }

    public void Stop()
    {
        _pollTimer.Stop();
        IsWatching = false;

        if (CurrentFileName != null)
        {
            CurrentFileName = null;
            _lastDetectedFile = null;
            FileChanged?.Invoke(null);
        }
    }

    private void Poll()
    {
        var fileName = DetectOpenFile();

        if (fileName == _lastDetectedFile) return;

        _lastDetectedFile = fileName;
        CurrentFileName = fileName;

        if (fileName != null)
        {
            StatusChanged?.Invoke($"Tracking: {fileName}");
        }
        else
        {
            StatusChanged?.Invoke("Warte auf Clip Studio Paint...");
        }

        FileChanged?.Invoke(fileName);
    }

    private string? DetectOpenFile()
    {
        foreach (var processName in CspProcessNames)
        {
            try
            {
                var processes = Process.GetProcessesByName(processName);
                foreach (var proc in processes)
                {
                    try
                    {
                        var title = proc.MainWindowTitle;
                        if (string.IsNullOrWhiteSpace(title)) continue;

                        var parsed = ParseFileName(title);
                        if (parsed != null) return parsed;
                    }
                    catch
                    {
                        // Prozess-Zugriff fehlgeschlagen
                    }
                    finally
                    {
                        proc.Dispose();
                    }
                }
            }
            catch
            {
                // GetProcessesByName fehlgeschlagen
            }
        }

        return null;
    }

    /// <summary>
    /// Extrahiert den Dateinamen aus dem Fenstertitel.
    /// Typische Formate:
    ///   "MeinBild.clip - CLIP STUDIO PAINT"
    ///   "MeinBild.clip [Geändert] - CLIP STUDIO PAINT"
    ///   "CLIP STUDIO PAINT - MeinBild.clip"
    /// </summary>
    private static string? ParseFileName(string windowTitle)
    {
        // Entferne bekannte Suffixe/Prefixe
        var parts = windowTitle.Split(new[] { " - " }, StringSplitOptions.RemoveEmptyEntries);

        foreach (var part in parts)
        {
            var cleaned = part.Trim();

            // Entferne [Geändert], [Modified], * etc.
            cleaned = cleaned
                .Replace("[Geändert]", "")
                .Replace("[Modified]", "")
                .Replace("*", "")
                .Trim();

            // Suche nach .clip Extension
            if (cleaned.EndsWith(".clip", StringComparison.OrdinalIgnoreCase))
            {
                return Path.GetFileNameWithoutExtension(cleaned);
            }
        }

        return null;
    }

    public void Dispose()
    {
        Stop();
        _pollTimer.Dispose();
    }
}
