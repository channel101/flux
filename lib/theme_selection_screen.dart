import 'package:flutter/material.dart';
import 'package:flux/theme_service.dart';
import 'package:flux/settings_service.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChanged;
  
  const ThemeSelectionScreen({
    Key? key,
    required this.onThemeChanged,
  }) : super(key: key);
  
  @override
  _ThemeSelectionScreenState createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String _selectedTheme = 'default';
  
  @override
  void initState() {
    super.initState();
    _loadSelectedTheme();
  }
  
  Future<void> _loadSelectedTheme() async {
    final savedTheme = await SettingsService.getSelectedTheme();
    setState(() {
      _selectedTheme = savedTheme;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Theme',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Accent Colors
            _buildSectionHeader('Accent Colors'),
            SizedBox(height: 16),
            _buildAccentColorsGrid(),
            
            SizedBox(height: 32),
            
            // Section: Preset Themes
            _buildSectionHeader('Preset Themes'),
            SizedBox(height: 16),
            _buildPresetThemesGrid(),
            
            SizedBox(height: 32),
            
            // Section: Dark Themes
            _buildSectionHeader('Dark Themes'),
            SizedBox(height: 16),
            _buildDarkThemesGrid(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAccentColorsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: ThemeService.accentColors.length,
      itemBuilder: (context, index) {
        final accentColor = ThemeService.accentColors[index];
        final themeKey = 'accent_${accentColor.colorName.toLowerCase()}';
        final theme = ThemeService.generateThemeFromAccent(accentColor.color);
        
        return _buildThemeCard(
          themeKey: themeKey,
          themeName: accentColor.colorName,
          theme: theme,
          primaryColor: accentColor.color,
        );
      },
    );
  }
  
  Widget _buildPresetThemesGrid() {
    final presetThemes = ThemeService.presetThemes.entries.toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: presetThemes.length,
      itemBuilder: (context, index) {
        final entry = presetThemes[index];
        final themeKey = entry.key;
        final theme = entry.value;
        
        return _buildThemeCard(
          themeKey: themeKey,
          themeName: _formatThemeName(themeKey),
          theme: theme,
          primaryColor: theme.colorScheme.primary,
        );
      },
    );
  }
  
  Widget _buildDarkThemesGrid() {
    final darkThemes = {
      'dark_minimal': ThemeService.generateMinimalDarkTheme(),
      'dark_vibrant': ThemeService.generateVibrantDarkTheme(),
      'dark_nature': ThemeService.generateNatureDarkTheme(),
    };
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: darkThemes.length,
      itemBuilder: (context, index) {
        final entry = darkThemes.entries.toList()[index];
        final themeKey = entry.key;
        final theme = entry.value;
        
        return _buildThemeCard(
          themeKey: themeKey,
          themeName: _formatThemeName(themeKey),
          theme: theme,
          primaryColor: theme.colorScheme.primary,
          isDark: true,
        );
      },
    );
  }
  
  Widget _buildThemeCard({
    required String themeKey,
    required String themeName,
    required ThemeData theme,
    required Color primaryColor,
    bool isDark = false,
  }) {
    final isSelected = _selectedTheme == themeKey;
    
    return GestureDetector(
      onTap: () => _selectTheme(themeKey, theme),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Header
                Container(
                  height: 40,
                  color: primaryColor,
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content area
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Sample card
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Theme name
                        Text(
                          themeName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: 4),
                        
                        // Color indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 2),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (isDark) ...[
                              SizedBox(width: 2),
                              Icon(
                                Icons.dark_mode,
                                size: 8,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    color: primaryColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatThemeName(String themeKey) {
    return themeKey
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  Future<void> _selectTheme(String themeKey, ThemeData theme) async {
    setState(() {
      _selectedTheme = themeKey;
    });
    
    await SettingsService.setSelectedTheme(themeKey);
    widget.onThemeChanged(theme);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme applied successfully! 🎨'),
        duration: Duration(seconds: 2),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
} 