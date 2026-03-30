using System;
using System.IO;
using System.Windows;
using System.Windows.Threading;

namespace ArtTimeTracker.Windows;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        // Globale Fehlerbehandlung - schreibt Crashes in eine Log-Datei
        DispatcherUnhandledException += OnUnhandledException;
        AppDomain.CurrentDomain.UnhandledException += OnDomainException;

        FartPlayer.Init();

        base.OnStartup(e);
    }

    private void OnUnhandledException(object sender, DispatcherUnhandledExceptionEventArgs e)
    {
        LogError(e.Exception);
        MessageBox.Show(
            $"Ein Fehler ist aufgetreten:\n\n{e.Exception.Message}\n\nDetails wurden in crash.log gespeichert.",
            "Tottis Arsch Tracker - Fehler",
            MessageBoxButton.OK,
            MessageBoxImage.Error);
        e.Handled = true;
    }

    private void OnDomainException(object sender, UnhandledExceptionEventArgs e)
    {
        if (e.ExceptionObject is Exception ex)
            LogError(ex);
    }

    private static void LogError(Exception ex)
    {
        try
        {
            var logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "crash.log");
            var entry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}]\n{ex}\n\n";
            File.AppendAllText(logPath, entry);
        }
        catch { }
    }
}
