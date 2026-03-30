using System;
using System.Timers;

namespace ArtTimeTracker.Core.Services;

public class TimerService : IDisposable
{
    private System.Timers.Timer? _timer;
    private DateTime _startTime;

    public bool IsRunning { get; private set; }
    public int? CurrentArtworkId { get; private set; }
    public string? CurrentArtworkName { get; private set; }
    public TimeSpan Elapsed => IsRunning ? DateTime.Now - _startTime : TimeSpan.Zero;

    public event Action? Tick;
    public event Action<int, string, DateTime, DateTime>? SessionCompleted;

    public void Start(int artworkId, string artworkName)
    {
        if (IsRunning && CurrentArtworkId == artworkId) return;
        if (IsRunning) Stop();

        CurrentArtworkId = artworkId;
        CurrentArtworkName = artworkName;
        _startTime = DateTime.Now;
        IsRunning = true;

        _timer = new System.Timers.Timer(1000);
        _timer.Elapsed += (_, _) => Tick?.Invoke();
        _timer.Start();
    }

    public void Stop()
    {
        if (!IsRunning) return;

        _timer?.Stop();
        _timer?.Dispose();
        _timer = null;

        var endTime = DateTime.Now;
        var artworkId = CurrentArtworkId!.Value;
        var artworkName = CurrentArtworkName!;

        IsRunning = false;
        CurrentArtworkId = null;
        CurrentArtworkName = null;

        if ((endTime - _startTime).TotalSeconds >= 5)
        {
            SessionCompleted?.Invoke(artworkId, artworkName, _startTime, endTime);
        }
    }

    public void Dispose()
    {
        Stop();
        _timer?.Dispose();
    }
}
