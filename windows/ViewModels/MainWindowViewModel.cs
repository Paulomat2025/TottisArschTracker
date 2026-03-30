using System;
using System.Threading.Tasks;
using System.Windows;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using ArtTimeTracker.Core.Models;
using ArtTimeTracker.Core.Services;

namespace ArtTimeTracker.Windows.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    private readonly DataService _dataService = new();
    private readonly TimerService _timerService = new();
    private readonly ProcessWatcher _processWatcher = new();

    [ObservableProperty]
    private ViewModelBase _currentView = null!;

    [ObservableProperty]
    private string _statusText = "Bereit";

    [ObservableProperty]
    private bool _isAutoTracking = true;

    public MainWindowViewModel()
    {
        _timerService.Tick += () => Application.Current?.Dispatcher.Invoke(() =>
        {
            if (_timerService.IsRunning)
            {
                var e = _timerService.Elapsed;
                StatusText = $"⏱ {_timerService.CurrentArtworkName} — {(int)e.TotalHours:D2}:{e.Minutes:D2}:{e.Seconds:D2}";
            }
        });

        _processWatcher.FileChanged += OnFileChanged;
        _processWatcher.StatusChanged += s => Application.Current?.Dispatcher.Invoke(() =>
        {
            if (!_timerService.IsRunning) StatusText = s;
        });

        _processWatcher.Start();
        NavigateToDashboard();
    }

    private async void OnFileChanged(string? fileName)
    {
        if (!IsAutoTracking) return;

        await Application.Current!.Dispatcher.InvokeAsync(async () =>
        {
            if (fileName == null)
            {
                _timerService.Stop();
                await RefreshDashboard();
                return;
            }

            var artwork = await _dataService.GetOrCreateByFileNameAsync(fileName);
            _timerService.Start(artwork.Id, artwork.Name);

            _timerService.SessionCompleted -= OnSessionCompleted;
            _timerService.SessionCompleted += OnSessionCompleted;

            await RefreshDashboard();
        });
    }

    private async void OnSessionCompleted(int artworkId, string name, DateTime start, DateTime end)
    {
        await _dataService.AddSessionAsync(artworkId, start, end);
        Application.Current?.Dispatcher.Invoke(async () => await RefreshDashboard());
    }

    private async Task RefreshDashboard()
    {
        if (CurrentView is DashboardViewModel dashboard)
            await dashboard.LoadAsync();
    }

    [RelayCommand]
    private void NavigateToDashboard()
    {
        var vm = new DashboardViewModel(_dataService, _timerService);
        vm.ArtworkSelected += OnArtworkSelected;
        CurrentView = vm;
        _ = vm.LoadAsync();
    }

    [RelayCommand]
    private void NavigateToStatistics()
    {
        var vm = new StatisticsViewModel(_dataService);
        CurrentView = vm;
        _ = vm.LoadAsync();
    }

    private void OnArtworkSelected(Artwork artwork)
    {
        var vm = new ArtworkDetailViewModel(_dataService);
        vm.BackRequested += NavigateToDashboard;
        CurrentView = vm;
        _ = vm.LoadAsync(artwork);
    }

    [RelayCommand]
    private void ToggleAutoTracking()
    {
        IsAutoTracking = !IsAutoTracking;
        if (IsAutoTracking)
        {
            _processWatcher.Start();
            StatusText = "Auto-Tracking aktiviert";
        }
        else
        {
            _processWatcher.Stop();
            _timerService.Stop();
            StatusText = "Auto-Tracking deaktiviert";
        }
    }
}
