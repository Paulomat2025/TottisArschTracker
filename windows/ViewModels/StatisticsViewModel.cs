using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using LiveChartsCore;
using LiveChartsCore.SkiaSharpView;
using LiveChartsCore.SkiaSharpView.Painting;
using SkiaSharp;
using ArtTimeTracker.Core.Services;

namespace ArtTimeTracker.Windows.ViewModels;

public partial class StatisticsViewModel : ViewModelBase
{
    private readonly DataService _dataService;

    [ObservableProperty] private ISeries[] _dailySeries = Array.Empty<ISeries>();
    [ObservableProperty] private Axis[] _dailyXAxes = Array.Empty<Axis>();
    [ObservableProperty] private Axis[] _dailyYAxes = new[] { new Axis { Name = "Stunden", MinLimit = 0 } };
    [ObservableProperty] private ISeries[] _artworkSeries = Array.Empty<ISeries>();
    [ObservableProperty] private Axis[] _artworkXAxes = Array.Empty<Axis>();
    [ObservableProperty] private Axis[] _artworkYAxes = new[] { new Axis { Name = "Stunden", MinLimit = 0 } };

    public StatisticsViewModel(DataService dataService) { _dataService = dataService; }

    public async Task LoadAsync()
    {
        var sessions = await _dataService.GetAllSessionsAsync(30);
        BuildDailyChart(sessions);
        BuildArtworkChart(sessions);
    }

    private void BuildDailyChart(List<Core.Models.TrackingSession> sessions)
    {
        var grouped = sessions.GroupBy(s => s.StartTime.Date).OrderBy(g => g.Key).ToList();
        var days = new List<(DateTime Date, double Hours)>();
        if (grouped.Count > 0)
            for (var d = grouped.First().Key; d <= DateTime.Today; d = d.AddDays(1))
                days.Add((d, grouped.FirstOrDefault(g => g.Key == d)?.Sum(s => s.Duration.TotalHours) ?? 0));

        DailySeries = new ISeries[] { new ColumnSeries<double> { Values = days.Select(d => Math.Round(d.Hours, 2)).ToArray(), Name = "Stunden", Fill = new SolidColorPaint(new SKColor(0xD0, 0xBC, 0xFF)) } };
        DailyXAxes = new[] { new Axis { Labels = days.Select(d => d.Date.ToString("dd.MM")).ToArray(), LabelsRotation = 45 } };
    }

    private void BuildArtworkChart(List<Core.Models.TrackingSession> sessions)
    {
        var grouped = sessions.GroupBy(s => s.Artwork?.Name ?? "?").OrderByDescending(g => g.Sum(s => s.Duration.TotalHours)).ToList();
        ArtworkSeries = new ISeries[] { new ColumnSeries<double> { Values = grouped.Select(g => Math.Round(g.Sum(s => s.Duration.TotalHours), 2)).ToArray(), Name = "Stunden", Fill = new SolidColorPaint(new SKColor(0x4F, 0x37, 0x8B)) } };
        ArtworkXAxes = new[] { new Axis { Labels = grouped.Select(g => g.Key).ToArray(), LabelsRotation = 45 } };
    }
}
