# Assets - Images

## Background GIF for Login Page

To complete the login page background setup, you need to add a GIF file named `login_background.gif` to this directory.

### Recommended GIF specifications:
- **File name**: `login_background.gif`
- **Dimensions**: 1080x1920 (portrait) or similar mobile-friendly aspect ratio
- **File size**: Keep under 5MB for optimal performance
- **Content**: Abstract patterns, subtle animations, or branded visuals that work well as backgrounds
- **Colors**: Should complement your app's color scheme (blues/gradients work well with the current theme)

### Fallback behavior:
If the GIF file is not found or fails to load, the app will automatically fall back to a beautiful gradient background with blue tones.

### Adding your GIF:
1. Place your GIF file in this directory: `/assets/images/login_background.gif`
2. Run `flutter pub get` to refresh assets
3. The login page will automatically use your GIF as the background

### Alternative options:
- You can also use static images (PNG/JPG) by changing the file extension in the code
- For better performance, consider using Lottie animations instead of GIFs
