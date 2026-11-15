import Ryu.Ipc
import px.configuration.Wallpaper
import px.services.theme

IpcHandler {
    target: "wallpaper"
    function setWallpaper(path: string): string {
        if (!path || path.length == 0) {
            return "invalid path";
        }
        WallpaperConfig.setWallpaper(path);
        Theme.generate();
        return "wallpaper set: " + path;
    }
    function setFolder(path: string): void {
        WallpaperConfig.setFolder(path);
    }
}
