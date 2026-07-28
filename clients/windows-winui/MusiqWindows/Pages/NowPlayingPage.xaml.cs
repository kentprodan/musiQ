using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class NowPlayingPage : Page
{
    public NowPlayingViewModel ViewModel { get; } = new();

    /// True between the slider's PointerPressed and PointerCaptureLost —
    /// while dragging, the position-poll timer's updates are suppressed so
    /// they don't fight the user's own drag.
    private bool _isSeeking;

    public NowPlayingPage()
    {
        InitializeComponent();
        ViewModel.PositionChanged += OnPositionChanged;
        Unloaded += (_, _) =>
        {
            ViewModel.PositionChanged -= OnPositionChanged;
            ViewModel.Detach();
        };
    }

    private void OnPositionChanged(double seconds)
    {
        if (_isSeeking)
        {
            return;
        }

        PositionSlider.Value = seconds;
        PositionText.Text = NowPlayingViewModel.FormatSeconds(seconds);
    }

    private void PositionSlider_PointerPressed(object sender, PointerRoutedEventArgs e)
    {
        _isSeeking = true;
    }

    private async void PositionSlider_PointerCaptureLost(object sender, PointerRoutedEventArgs e)
    {
        _isSeeking = false;
        await ViewModel.SeekAsync(PositionSlider.Value);
    }
}
