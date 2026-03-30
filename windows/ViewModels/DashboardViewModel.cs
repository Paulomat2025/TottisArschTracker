using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using ArtTimeTracker.Core.Models;
using ArtTimeTracker.Core.Services;

namespace ArtTimeTracker.Windows.ViewModels;

public partial class DashboardViewModel : ViewModelBase
{
    private readonly DataService _dataService;
    private readonly TimerService _timerService;

    [ObservableProperty]
    private ObservableCollection<ArtworkDisplayItem> _artworks = new();

    [ObservableProperty]
    private string _elapsedText = "00:00:00";

    [ObservableProperty]
    private string _trackingLabel = "Kein aktives Tracking";

    [ObservableProperty]
    private bool _isTimerRunning;

    [ObservableProperty]
    private ObservableCollection<SessionDisplayItem> _recentSessions = new();

    [ObservableProperty]
    private string _newArtworkName = string.Empty;

    public event Action<Artwork>? ArtworkSelected;

    public DashboardViewModel(DataService dataService, TimerService timerService)
    {
        _dataService = dataService;
        _timerService = timerService;
        _timerService.Tick += OnTimerTick;
    }

    public async Task LoadAsync()
    {
        var artworks = await _dataService.GetArtworksAsync();
        Artworks = new ObservableCollection<ArtworkDisplayItem>(
            artworks.Select(a =>
            {
                var total = TimeSpan.FromTicks(a.Sessions.Sum(s => s.Duration.Ticks));
                return new ArtworkDisplayItem { Artwork = a, Name = a.Name, LinkedFile = a.LinkedFileName, TotalTime = FormatDuration(total), SessionCount = a.Sessions.Count };
            }));

        var sessions = await _dataService.GetAllSessionsAsync(7);
        RecentSessions = new ObservableCollection<SessionDisplayItem>(
            sessions.Select(s => new SessionDisplayItem { ArtworkName = s.Artwork?.Name ?? "?", Date = s.StartTime.ToString("dd.MM.yyyy HH:mm"), Duration = FormatDuration(s.Duration) }));

        IsTimerRunning = _timerService.IsRunning;
        TrackingLabel = _timerService.IsRunning ? $"Tracking: {_timerService.CurrentArtworkName}" : "Kein aktives Tracking";
    }

    [RelayCommand]
    private async Task AddArtwork()
    {
        if (string.IsNullOrWhiteSpace(NewArtworkName)) return;
        await _dataService.AddArtworkAsync(NewArtworkName.Trim());
        NewArtworkName = string.Empty;
        await LoadAsync();
    }

    [RelayCommand]
    private void OpenArtworkDetail(ArtworkDisplayItem? item)
    {
        if (item?.Artwork != null) ArtworkSelected?.Invoke(item.Artwork);
    }

    private void OnTimerTick()
    {
        var elapsed = _timerService.Elapsed;
        ElapsedText = $"{(int)elapsed.TotalHours:D2}:{elapsed.Minutes:D2}:{elapsed.Seconds:D2}";
        IsTimerRunning = _timerService.IsRunning;
    }

    public static string FormatDuration(TimeSpan ts)
    {
        if (ts.TotalHours >= 1) return $"{(int)ts.TotalHours}h {ts.Minutes:D2}m";
        if (ts.TotalMinutes >= 1) return $"{ts.Minutes}m {ts.Seconds:D2}s";
        return $"{ts.Seconds}s";
    }
}

public class ArtworkDisplayItem
{
    public Artwork Artwork { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string? LinkedFile { get; set; }
    public string LinkedFileDisplay => LinkedFile != null ? $"📎 {LinkedFile}.clip" : "Keine Datei verknüpft";
    public string TotalTime { get; set; } = "0s";
    public int SessionCount { get; set; }
}

public class SessionDisplayItem
{
    public string ArtworkName { get; set; } = string.Empty;
    public string Date { get; set; } = string.Empty;
    public string Duration { get; set; } = string.Empty;
}
