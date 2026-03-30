using System;
using System.IO;
using System.Media;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;

namespace ArtTimeTracker.Windows;

public static class FartPlayer
{
    private static SoundPlayer? _player;

    public static void Init()
    {
        var path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "fart-sound.wav");
        if (File.Exists(path))
            _player = new SoundPlayer(path);

        // Buttons
        EventManager.RegisterClassHandler(typeof(Button), Button.ClickEvent, new RoutedEventHandler((_, _) => Play()));

        // Text input (jeder Tastendruck)
        EventManager.RegisterClassHandler(typeof(TextBox), TextBox.PreviewTextInputEvent, new TextCompositionEventHandler((_, _) => Play()));

        // Menüpunkte / ListItems
        EventManager.RegisterClassHandler(typeof(ListBoxItem), ListBoxItem.SelectedEvent, new RoutedEventHandler((_, _) => Play()));
        EventManager.RegisterClassHandler(typeof(ListViewItem), ListViewItem.SelectedEvent, new RoutedEventHandler((_, _) => Play()));
        EventManager.RegisterClassHandler(typeof(ComboBox), ComboBox.DropDownOpenedEvent, new EventHandler((_, _) => Play()));
        EventManager.RegisterClassHandler(typeof(TabItem), Selector.SelectedEvent, new RoutedEventHandler((_, _) => Play()));

        // Programm geöffnet
        Play();
    }

    public static void Play()
    {
        _player?.Play();
    }
}
