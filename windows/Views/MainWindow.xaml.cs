using System.Windows;
using ArtTimeTracker.Windows.ViewModels;

namespace ArtTimeTracker.Windows.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Closing += (_, _) =>
        {
            if (DataContext is MainWindowViewModel vm)
                vm.QuitAppCommand.Execute(null);
        };
    }
}
