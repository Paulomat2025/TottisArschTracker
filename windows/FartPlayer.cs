using System;
using System.IO;
using System.Media;
using System.Windows;
using System.Windows.Controls;

namespace ArtTimeTracker.Windows;

public static class FartPlayer
{
    private static SoundPlayer? _player;

    public static void Init()
    {
        var path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "fart-sound.wav");
        if (File.Exists(path))
            _player = new SoundPlayer(path);

        // Hook auf ALLE Buttons in der ganzen App
        EventManager.RegisterClassHandler(typeof(Button), Button.ClickEvent, new RoutedEventHandler((_, _) => Play()));
    }

    public static void Play()
    {
        _player?.Play();
    }
}
