using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class SourcesPage : Page
{
    public SourcesViewModel ViewModel { get; } = new();

    public SourcesPage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        // Refresh every time the page is shown, since a scan on the Library
        // page may have added a new source since our last visit.
        _ = ViewModel.RefreshCommand.ExecuteAsync(null);
    }
}
