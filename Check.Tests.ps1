# Checks your morning script and your answers, one test per job and per question in README.md.
# It runs your script the way someone else would: a copy of it, with a to-do list of the check's own beside
# it, started with pwsh -File from another folder, as a user named Maya. The copy lives in a throwaway folder
# Pester makes and removes (TestDrive), so your own files are never changed.
# Run it from this folder with: Invoke-Pester
# You don't need to change this file.

Describe 'Exercise: A Morning Start-Up Script' {

    BeforeAll {
        $script:scriptPath = Join-Path $PSScriptRoot 'morning.ps1'

        # Read the script the way PowerShell does, without running it: its tokens (comments included),
        # its statements and any mistake that would stop it from running at all.
        $script:tokens = @()
        $script:statements = 0
        $script:parseProblem = ''
        if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
            $parsedTokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref] $parsedTokens, [ref] $parseErrors)
            $script:tokens = @($parsedTokens | Where-Object { $_.Kind -notin 'NewLine', 'EndOfInput' })
            $script:statements = 0
            foreach ($block in $ast.BeginBlock, $ast.ProcessBlock, $ast.EndBlock) {
                if ($block) { $script:statements += $block.Statements.Count }
            }
            if ($parseErrors) {
                $first = $parseErrors[0]
                $script:parseProblem = "line $($first.Extent.StartLineNumber): $($first.Message)"
            }
        }

        # Fails the test with a message while morning.ps1 is missing, can't be read, or has no commands yet.
        function Assert-ScriptReady {
            Test-Path -LiteralPath $scriptPath -PathType Leaf | Should -BeTrue -Because 'morning.ps1 lives in this folder. Did it get moved or renamed?'
            $parseProblem | Should -BeNullOrEmpty -Because "PowerShell can't read morning.ps1, so none of it runs. The first mistake is on $parseProblem"
            $statements | Should -BeGreaterThan 0 -Because 'morning.ps1 has no commands yet, only comments. Write the commands for the jobs under your comment'
        }

        # Runs a copy of the script with pwsh -File from another folder, as Maya, with the check's own to-do
        # list beside it. Gives back the lines it printed and the errors it wrote.
        $script:run = $null
        if ((Test-Path -LiteralPath $scriptPath -PathType Leaf) -and -not $parseProblem -and $statements -gt 0) {
            $scriptsFolder = Join-Path $TestDrive 'Scripts'
            $elsewhere = Join-Path $TestDrive 'elsewhere'
            New-Item -ItemType Directory -Force -Path $scriptsFolder, $elsewhere | Out-Null
            $copy = Join-Path $scriptsFolder 'morning.ps1'
            Set-Content -LiteralPath $copy -Value (Get-Content -LiteralPath $scriptPath -Raw)
            Set-Content -LiteralPath (Join-Path $scriptsFolder 'todo.txt') -Value 'Feed the cat', 'Return the library books', 'Book a haircut'
            $pwsh = (Get-Process -Id $PID).Path
            $oldUser = $env:USERNAME
            $env:USERNAME = 'Maya'
            Push-Location -LiteralPath $elsewhere
            try {
                $all = @(& $pwsh -NoProfile -NonInteractive -File $copy 2>&1)
            }
            finally {
                Pop-Location
                $env:USERNAME = $oldUser
            }
            $script:run = [pscustomobject]@{
                Output = @($all | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
                # Every line the script wrote as an error, in one piece, with runs of spaces made single.
                Errors = (@($all | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join ' ') -replace '\s+', ' '
            }
        }

        # The answers in answers.txt: the text after "N)", with runs of spaces made single.
        $script:answers = @{}
        foreach ($line in Get-Content (Join-Path $PSScriptRoot 'answers.txt')) {
            if ($line -match '^\s*(\d+)\)\s*(.*)$') {
                $script:answers[[int]$Matches[1]] = ($Matches[2].Trim() -replace '\s+', ' ')
            }
        }
    }

    It '1) a comment at the top says what the script does' {
        Assert-ScriptReady
        $first = $tokens | Select-Object -First 1
        $first.Kind | Should -Be 'Comment' -Because 'the very first thing in morning.ps1 should be a comment: # and a note that says what the script does'
        $first.Text | Should -Not -Match 'delete these comments' -Because 'the first comment is still the starter''s instruction. Replace it with your own note, such as # morning.ps1: my start-of-the-day check.'
        $first.Text | Should -Match '[A-Za-z]{3}' -Because 'the comment should say in words what the script does'
    }

    It 'the script runs without an error, from another folder' {
        Assert-ScriptReady
        $run.Errors | Should -BeNullOrEmpty -Because "run from another folder, morning.ps1 wrote an error. Run it yourself from your home folder (Set-Location ~, then the script's full path) and read the first error"
    }

    It '2) it greets whoever runs it' {
        Assert-ScriptReady
        ($run.Output -join "`n") | Should -Match 'Maya' -Because 'run by a user named Maya, the script should greet Maya. Use $env:USERNAME in the greeting, not your own name: Write-Output "Good morning, $env:USERNAME!"'
    }

    It '3) it shows today''s date' {
        Assert-ScriptReady
        $today = Get-Date -Format 'dddd'
        ($run.Output -join "`n") | Should -Match $today -Because "the output should show today's day of the week ($today). Get-Date -Format 'dddd, MMMM d' gives it"
    }

    It '4) it shows the to-do list beside the script, from any folder' {
        Assert-ScriptReady
        $text = $run.Output -join "`n"
        $hint = if ($run.Errors -match 'Cannot find path') {
            'from another folder, the script couldn''t find todo.txt. A script runs in the folder you''re in, so name the file with the script''s own folder: "$PSScriptRoot\todo.txt"'
        }
        else {
            'the check put its own list ("Feed the cat" and two more) in todo.txt beside the script, and the output doesn''t show it. Read the list with Get-Content from that file; don''t type its lines into the script'
        }
        foreach ($item in 'Feed the cat', 'Return the library books', 'Book a haircut') {
            $text | Should -Match ([regex]::Escape($item)) -Because $hint
        }
    }

    It '5) it shows the free space, in GB' {
        Assert-ScriptReady
        ($run.Output -join "`n") | Should -Match '\d.*GB' -Because 'the output should show the free space with GB after the number, such as Free space on C: 805.8 GB. (Get-PSDrive -Name C).Free / 1GB is the free space in gigabytes'
    }

    It 'answer 1) running the script from its own folder' {
        $answers[1] | Should -Not -BeNullOrEmpty -Because 'question 1 has no answer yet'
        $answers[1] | Should -Match '^\.[\\/]morning(\.ps1)?$' -Because 'PowerShell never looks in the current folder by itself: the line needs .\ in front of the name'
    }

    It 'answer 2) the Scripts folder on PATH for this window' {
        $answers[2] | Should -Not -BeNullOrEmpty -Because 'question 2 has no answer yet'
        $answers[2] | Should -Match '^\$env:PATH \+= ' -Because 'the line starts $env:PATH += : += adds to the end and keeps every folder already there, where = would throw them away'
        $answers[2] | Should -Match '^\$env:PATH \+= "?;\$HOME[\\/]Scripts"?$' -Because 'the text added is ; and the folder, in double quotes so $HOME is filled in: ";$HOME\Scripts"'
    }

    It 'answer 3) the shortcut''s target' {
        $answers[3] | Should -Not -BeNullOrEmpty -Because 'question 3 has no answer yet'
        $answers[3] | Should -Match '^"?(C:\\Program Files\\PowerShell\\7\\)?pwsh(\.exe)?"? ' -Because 'the target starts with the program the shortcut runs: pwsh.exe, PowerShell 7'
        $answers[3] | Should -Match '-File "?C:\\Users\\Sam\\Scripts\\morning\.ps1"?$' -Because 'it ends with -File and the script''s full path, C:\Users\Sam\Scripts\morning.ps1'
        $answers[3] | Should -Match ' -NoExit .*-File ' -Because 'the window stays open with -NoExit, and it must come before -File: anything after the script''s path is handed to the script'
    }
}
