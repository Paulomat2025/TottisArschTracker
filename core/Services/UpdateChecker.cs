using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

namespace ArtTimeTracker.Core.Services;

public class UpdateChecker
{
    private const string ReleasesUrl = "https://api.github.com/repos/Paulomat2025/TottisArschTracker/releases/latest";

    public record UpdateInfo(string Version, string DownloadUrl, string ReleaseUrl);

    public static async Task<UpdateInfo?> CheckForUpdateAsync(string currentVersion)
    {
        try
        {
            using var http = new HttpClient();
            http.DefaultRequestHeaders.Add("User-Agent", "TottisArschTracker");
            http.Timeout = TimeSpan.FromSeconds(10);

            var json = await http.GetStringAsync(ReleasesUrl);
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var tagName = root.GetProperty("tag_name").GetString()?.TrimStart('v') ?? "";
            var releaseUrl = root.GetProperty("html_url").GetString() ?? "";

            if (string.Compare(tagName, currentVersion, StringComparison.OrdinalIgnoreCase) <= 0)
                return null;

            var downloadUrl = releaseUrl;
            if (root.TryGetProperty("assets", out var assets))
            {
                foreach (var asset in assets.EnumerateArray())
                {
                    var name = asset.GetProperty("name").GetString() ?? "";
                    if (name.Contains("Windows", StringComparison.OrdinalIgnoreCase) && name.EndsWith(".zip"))
                    {
                        downloadUrl = asset.GetProperty("browser_download_url").GetString() ?? releaseUrl;
                        break;
                    }
                }
            }

            return new UpdateInfo(tagName, downloadUrl, releaseUrl);
        }
        catch
        {
            return null;
        }
    }
}
