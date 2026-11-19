// Applied over prefs.js at every start; about:config changes to these don't stick.
// Load chrome/userChrome.css (Ember/Dust frame colors).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// See-through frame so niri's blur shows behind it; pages stay opaque.
user_pref("zen.widget.linux.transparency", true);
