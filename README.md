# Exercise: A Morning Start-Up Script

Exercise code for the lesson **Exercise: A Morning Start-Up Script** in PowerShell in Depth on [ask-codey.com](https://www.ask-codey.com).

Every morning starts with the same small jobs: a hello, the date, your to-do list and a look at the free space on your drive. Write them once, as a script, so one line does them all. A Pester check runs your script the way someone else would, from another folder and as another user, and tells you what's done.

## What's here

- `morning.ps1`: your script. It holds only a comment with the jobs for now. For you to write.
- `todo.txt`: a sample to-do list, the file your script reads. It stays beside the script.
- `answers.txt`: three questions about running your script, each with a numbered line for your answer. For you to finish.
- `Check.Tests.ps1`: the check. You don't need to change it.

## What to do

Open PowerShell 7 in this folder (the one with `answers.txt` in it), then open the script in VS Code or `edit`:

```powershell
code .\morning.ps1
```

Replace the starter's comment with your own script:

1. **A comment at the top** that says what the script does.
2. **A greeting** for whoever runs it, with `$env:USERNAME`.
3. **Today's date**, with the day's name, from `Get-Date -Format`.
4. **The to-do list** in `todo.txt`, the file beside the script, found from any folder with `$PSScriptRoot`.
5. **The free space on drive C**, in GB, from `Get-PSDrive`. On a Mac or Linux, the drive is `/`.

Save, and try it as you go:

```powershell
.\morning.ps1
```

Then go to your home folder with `Set-Location ~` and run it by its full path: it should still show your list. Finally, answer the three questions in `answers.txt`, and save it.

## Check your work

The check needs Pester 5 or newer. Install it once, if you haven't already:

```powershell
Install-PSResource Pester
```

Then, from this folder:

```powershell
Invoke-Pester
```

At first most tests fail: that is expected. Each job you finish turns its test green. A failing test's message says what to look at. The check runs a copy of your script in a throwaway folder, from another folder, as a user named Maya, with a to-do list of its own beside it; it never changes your files.

If PowerShell says the check *cannot be loaded* because it *is not digitally signed*, or because *running scripts is disabled*, the folder came from a download that Windows marked as from the internet. Unblock its files once with `Get-ChildItem -Recurse | Unblock-File`, from this folder, and run `Invoke-Pester` again. *Why a Script Won't Run: The Execution Policy* explains what that does.

## The rules

- Keep the script in `morning.ps1`, and its list in `todo.txt` beside it.
- Greet `$env:USERNAME`, not your own name, and read the list from its file: the check uses its own user name and list.
- Write each answer on its numbered line, after the `)`, like the example: `0) Get-Location`.

## Tips

- A script runs in the folder you're in, not the folder it's saved in. `"$PSScriptRoot\todo.txt"` is the list beside the script, wherever you are.
- `Get-Date -Format 'dddd, MMMM d'` gives the day's name, the month and the day.
- `(Get-PSDrive -Name C).Free / 1GB` is the free space in gigabytes, and `[math]::Round( , 1)` cuts it to one decimal place.
- Write-Output with empty quotes, `Write-Output ''`, prints an empty line to space the output out.
- An error when you run the script? The message names the line: look there first.

## Make it yours

When every test passes, make it a command of your own. Make a Scripts folder, copy `morning.ps1` and `todo.txt` into it, and add the folder to your `PATH` in your profile (keep a copy of your profile first), so `morning` works in every window. Then, if you like, make a desktop shortcut to it, as *Run It from Anywhere* shows, and start your day with a double-click.

## Hand it in

When it works, push your solution to a public repo of your own on GitHub, then paste that repo's address into **Submit your exercise** on the lesson page at [ask-codey.com](https://www.ask-codey.com). That's what completes the lesson. The lesson page shows the Git commands, step by step.
