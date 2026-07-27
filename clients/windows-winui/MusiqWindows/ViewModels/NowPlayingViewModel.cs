using CommunityToolkit.Mvvm.ComponentModel;

namespace MusiqWindows.ViewModels;

/// <summary>
/// Genuinely minimal — musiQ's audio playback engine doesn't exist yet
/// (Phase 1 only covers library scanning + the Windows shell), so this page
/// honestly reports "nothing playing" instead of faking transport controls
/// that don't do anything.
/// </summary>
public partial class NowPlayingViewModel : ObservableObject
{
    [ObservableProperty]
    private string _statusMessage = "Nothing is playing. musiQ's playback engine hasn't been built yet.";
}
