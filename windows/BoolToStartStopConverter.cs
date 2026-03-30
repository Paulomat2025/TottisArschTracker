using System;
using System.Globalization;
using System.Windows.Data;

namespace ArtTimeTracker.Windows;

public class BoolToStartStopConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        => value is true ? "Stop" : "Start";

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotSupportedException();
}
