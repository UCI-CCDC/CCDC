#Sets the keyboard language to english us
Set-WinUserLanguageList -LanguageList en-US -Force

#Sets the theme to default
#This should also disable high contrast and other accessiblity settings
C:\Windows\resources\Themes\aero.theme

#Sets the system language to english us
Set-WinSystemLocale en-US

#Reg files for the font settings
#Runs the reg files (might manually add the reg code here and have the script create then run the files)
reg import .\Change-Font.reg
reg import .\Reset-Font.reg
