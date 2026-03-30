using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using ArtTimeTracker.Core.Models;
using ArtTimeTracker.Core.Services;

namespace ArtTimeTracker.Windows.ViewModels;

public partial class ArtworkDetailViewModel : ViewModelBase
{
    private readonly DataService _dataService;
    private Artwork _artwork = null!;

    [ObservableProperty] private string _artworkName = string.Empty;
    [ObservableProperty] private string _totalTime = "0h 00m";
    [ObservableProperty] private ObservableCollection<SessionDetailItem> _sessions = new();
    [ObservableProperty] private SessionDetailItem? _selectedSession;
    [ObservableProperty] private ObservableCollection<MergeCandidate> _mergeCandidates = new();
    [ObservableProperty] private MergeCandidate? _selectedMergeCandidate;
    [ObservableProperty] private bool _isMergePanelVisible;
    [ObservableProperty] private string _linkedFileName = string.Empty;
    [ObservableProperty] private string _linkedFileDisplay = "Keine Datei verknüpft";
    [ObservableProperty] private bool _isRelinkPanelVisible;
    [ObservableProperty] private string _relinkFileName = string.Empty;

    public event Action? BackRequested;

    public ArtworkDetailViewModel(DataService dataService) { _dataService = dataService; }

    public async Task LoadAsync(Artwork artwork)
    {
        _artwork = artwork;
        ArtworkName = artwork.Name;
        LinkedFileName = artwork.LinkedFileName ?? "";
        LinkedFileDisplay = artwork.LinkedFileName != null ? $"📎 {artwork.LinkedFileName}.clip" : "Keine Datei verknüpft";
        var sessions = await _dataService.GetSessionsForArtworkAsync(artwork.Id);
        Sessions = new ObservableCollection<SessionDetailItem>(
            sessions.Select(s => new SessionDetailItem { Id = s.Id, Date = s.StartTime.ToString("dd.MM.yyyy"), StartTime = s.StartTime.ToString("HH:mm"), EndTime = s.EndTime.ToString("HH:mm"), Duration = DashboardViewModel.FormatDuration(s.Duration) }));
        var total = TimeSpan.FromTicks(sessions.Sum(s => s.Duration.Ticks));
        TotalTime = $"{(int)total.TotalHours}h {total.Minutes:D2}m";
    }

    [RelayCommand] private void GoBack() => BackRequested?.Invoke();

    [RelayCommand]
    private async Task DeleteSession()
    {
        if (SelectedSession == null) return;
        await _dataService.DeleteSessionAsync(SelectedSession.Id);
        await LoadAsync(_artwork);
    }

    [RelayCommand]
    private async Task ArchiveArtwork()
    {
        _artwork.IsArchived = true;
        await _dataService.UpdateArtworkAsync(_artwork);
        BackRequested?.Invoke();
    }

    [RelayCommand]
    private async Task ShowMergePanel()
    {
        var allArtworks = await _dataService.GetArtworksAsync(includeArchived: true);
        MergeCandidates = new ObservableCollection<MergeCandidate>(
            allArtworks.Where(a => a.Id != _artwork.Id)
                .Select(a => new MergeCandidate { Id = a.Id, Name = a.Name, SessionCount = a.Sessions.Count }));
        IsMergePanelVisible = true;
    }

    [RelayCommand]
    private async Task MergeSelected()
    {
        if (SelectedMergeCandidate == null) return;
        await _dataService.MergeArtworksAsync(_artwork.Id, SelectedMergeCandidate.Id);
        IsMergePanelVisible = false;
        await LoadAsync(_artwork);
    }

    [RelayCommand]
    private void CancelMerge() => IsMergePanelVisible = false;

    [RelayCommand]
    private void ShowRelinkPanel()
    {
        RelinkFileName = _artwork.LinkedFileName ?? "";
        IsRelinkPanelVisible = true;
    }

    [RelayCommand]
    private async Task PickFile()
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Clip Studio Paint Datei wählen",
            Filter = "Clip Studio Dateien (*.clip)|*.clip",
            Multiselect = false
        };
        if (dialog.ShowDialog() == true)
        {
            var fileName = System.IO.Path.GetFileNameWithoutExtension(dialog.FileName);
            await _dataService.RelinkArtworkAsync(_artwork.Id, fileName);
            _artwork.LinkedFileName = fileName;
            IsRelinkPanelVisible = false;
            await LoadAsync(_artwork);
        }
    }

    [RelayCommand]
    private async Task Relink()
    {
        var name = RelinkFileName.Trim();
        await _dataService.RelinkArtworkAsync(_artwork.Id, string.IsNullOrEmpty(name) ? null : name);
        _artwork.LinkedFileName = string.IsNullOrEmpty(name) ? null : name;
        IsRelinkPanelVisible = false;
        await LoadAsync(_artwork);
    }

    [RelayCommand]
    private async Task Unlink()
    {
        await _dataService.RelinkArtworkAsync(_artwork.Id, null);
        _artwork.LinkedFileName = null;
        await LoadAsync(_artwork);
    }

    [RelayCommand]
    private void CancelRelink() => IsRelinkPanelVisible = false;
}

public class MergeCandidate
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SessionCount { get; set; }
}

public class SessionDetailItem
{
    public int Id { get; set; }
    public string Date { get; set; } = string.Empty;
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public string Duration { get; set; } = string.Empty;
}
