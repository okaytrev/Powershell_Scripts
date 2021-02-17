
Add-Type -AssemblyName System.Speech
 
[int]$guess = 0
[int]$attempt = 0
[int]$number = Get-Random -Minimum 1 -Maximum 100
 
$voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voice.Speak("Hello Hardware Solutions you have seven trys to guess my number")
 
do {
    $voice.SpeakAsync("What's your guess?") | Out-Null
 
    try {
        $guess = Read-Host "What's your guess?"
 
        if ($guess -lt 1 -or $guess -gt 100) {
            throw
        }
    }
    catch {
        $voice.Speak("Invalid number")
        continue
    }
 
    if ($guess -lt $number) {
        $voice.Speak("Sorry you are Too low, ")
    }
    elseif ($guess -gt $number) {
        $voice.Speak("That's too high, try again")
    }
 
    $attempt += 1
}
until ($guess -eq $number -or $attempt -eq 7)
 
if ($guess -eq $number) {
    $voice.Speak("How did you guess that right! You sure are a wizard")
}
else {
    $voice.Speak("Oh know, I'm so sorry you are out of guesses, the correct number was $number")
}