/*
 * Tests for EnVar plugin for NSIS
 *
 * Copyright (C) 2020 Gilbertsoft LLC
 *
 */

!ifndef ANSICODE
  Unicode true
!endif

Name "EnVar Plugin Test"
OutFile "PluginTest.exe"
Caption "$(^Name)"
ShowInstDetails show
XPStyle on
RequestExecutionLevel user

# Error codes
!define ERR_SUCCESS    0
!define ERR_NOREAD     1
!define ERR_NOVARIABLE 2
!define ERR_NOVALUE    3
!define ERR_NOWRITE    4

# Variables
Var LogFile
Var Subject
Var Expected
Var Returned
Var ErrorCount
Var Counter
Var CounterFormatted

ReserveFile /plugin EnVar.dll

#Page components "" ""
#Page instfiles

!define LogMessage `!insertmacro LogMessage`
!macro LogMessage _Message
  DetailPrint "${_Message}"
  FileWrite $LogFile "${_Message}$\n"
!macroend

!define IncError `!insertmacro IncError`
!macro IncError
  IntOp $ErrorCount $ErrorCount + 1
!macroend

!define TestStart `!insertmacro TestStart`
!macro TestStart _Subject
	StrCpy $Subject "${_Subject}"
	Call TestStart
!macroend

!define TestEnd `!insertmacro TestEnd`
!macro TestEnd _Expected
	StrCpy $Expected ${_Expected}
	Call TestEnd
!macroend

Function TestStart
	${LogMessage} 'START $Subject'

	StrCpy $0 !0
	StrCpy $1 !1
	StrCpy $2 !2
	StrCpy $3 !3
	StrCpy $4 !4
	StrCpy $5 !5
	StrCpy $6 !6
	StrCpy $7 !7
	StrCpy $8 !8
	StrCpy $9 !9
	StrCpy $R0 !R0
	StrCpy $R1 !R1
	StrCpy $R2 !R2
	StrCpy $R3 !R3
	StrCpy $R4 !R4
	StrCpy $R5 !R5
	StrCpy $R6 !R6
	StrCpy $R7 !R7
	StrCpy $R8 !R8
	StrCpy $R9 !R9
FunctionEnd

Function TestEnd
  # Get return value
  Pop $Returned

  # Check for unexpected errors
	IfErrors ErrorFailed
	${LogMessage} 'PASSED $Subject no errors'
	Goto ReturnStart

  ErrorFailed:
  ${IncError}
	${LogMessage} 'FAILED $Subject error'
  Goto StackStart

  # Check return value against expectation
  ReturnStart:
  StrCmp $Returned $Expected 0 ReturnFailed
	${LogMessage} 'PASSED $Subject returned $Returned'
	Goto StackStart

  ReturnFailed:
  ${IncError}
	${LogMessage} 'FAILED $Subject returned $Returned'

  # Check for empty stack
  StackStart:
  ClearErrors
  Pop $Returned
	IfErrors 0 StackFailed
	${LogMessage} 'PASSED $Subject stack'
  Goto RegisterStart

  StackFailed:
  ${IncError}
	${LogMessage} 'FAILED $Subject stack $Returned'

  # Check registers
  RegisterStart:
	StrCmp $0 '!0' 0 error
	StrCmp $1 '!1' 0 error
	StrCmp $2 '!2' 0 error
	StrCmp $3 '!3' 0 error
	StrCmp $4 '!4' 0 error
	StrCmp $5 '!5' 0 error
	StrCmp $6 '!6' 0 error
	StrCmp $7 '!7' 0 error
	StrCmp $8 '!8' 0 error
	StrCmp $9 '!9' 0 error
	StrCmp $R0 '!R0' 0 error
	StrCmp $R1 '!R1' 0 error
	StrCmp $R2 '!R2' 0 error
	StrCmp $R3 '!R3' 0 error
	StrCmp $R4 '!R4' 0 error
	StrCmp $R5 '!R5' 0 error
	StrCmp $R6 '!R6' 0 error
	StrCmp $R7 '!R7' 0 error
	StrCmp $R8 '!R8' 0 error
	StrCmp $R9 '!R9' 0 error
	${LogMessage} 'PASSED $Subject register'
	goto end

	error:
  ${IncError}
	${LogMessage} 'FAILED $Subject register'
;	MessageBox MB_OKCANCEL '$$0={$0}$\n$$1={$1}$\n$$2={$2}$\n$$3={$3}$\n$$4={$4}$\n$$5={$5}$\n$$6={$6}$\n$$7={$7}$\n$$8={$8}$\n$$9={$9}$\n$$R0={$R0}$\n$$R1={$R1}$\n$$R2={$R2}$\n$$R3={$R3}$\n$$R4={$R4}$\n$$R5={$R5}$\n$$R6={$R6}$\n$$R7={$R7}$\n$$R8={$R8}$\n$$R9={$R9}' IDOK +2
;	quit

	end:
FunctionEnd

Function .onInit
  IntOp $ErrorCount $ErrorCount * 0
  FileOpen $LogFile "$EXEDIR\PluginTest.log" "w"
FunctionEnd

Section "Test EnVar::Check"
	${TestStart} "Check returns error with empty variable name"
  EnVar::Check "" ""
	${TestEnd} ${ERR_NOVARIABLE}

	${TestStart} "Check write access returns success for HKCU"
  EnVar::Check "NULL" "NULL"
	${TestEnd} ${ERR_SUCCESS}

  !ifdef RISKY
	${TestStart} "Check write access returns error for HKLM"
  EnVar::SetHKLM
  EnVar::Check "NULL" "NULL"
  EnVar::SetHKCU
	${TestEnd} ${ERR_NOWRITE}
  !endif

	${TestStart} "Check returns error for non existing variable name"
  EnVar::Check "NsisEnVarDummyVariable" ""
	${TestEnd} ${ERR_NOVARIABLE}

	${TestStart} "Check returns error for empty path"
  EnVar::Check "TEMP" ""
	${TestEnd} ${ERR_NOVARIABLE}

  # Testing for two possible failures with AppendSemiColon not possible

	${TestStart} "Check returns error if path not found"
  EnVar::Check "TEMP" "Z:\NsisEnVarInvalidPath"
	${TestEnd} ${ERR_NOVALUE}

	${TestStart} "Check returns success if path found"
  WriteRegStr HKCU "Environment" "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  EnVar::Check "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
	${TestEnd} ${ERR_SUCCESS}

	${TestStart} "Check returns error for unsupported type"
  WriteRegDWORD HKCU "Environment" "NsisEnVarTestVariable" "0"
  EnVar::Check "NsisEnVarTestVariable" "NULL"
  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
	${TestEnd} ${ERR_NOVARIABLE}

	${TestStart} "Check returns success for type REG_SZ"
  WriteRegStr HKCU "Environment" "NsisEnVarTestVariable" ""
  EnVar::Check "NsisEnVarTestVariable" "NULL"
  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
	${TestEnd} ${ERR_SUCCESS}

	${TestStart} "Check returns success for type REG_EXPAND_SZ"
  WriteRegExpandStr HKCU "Environment" "NsisEnVarTestVariable" ""
  EnVar::Check "NsisEnVarTestVariable" "NULL"
  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
	${TestEnd} ${ERR_SUCCESS}
SectionEnd

Section "Test EnVar::AddValue"
	${TestStart} "AddValue returns error for empty path"
  EnVar::AddValue "NsisEnVarTestVariable" ""
	${TestEnd} ${ERR_NOVALUE}

  !ifdef RISKY
	${TestStart} "AddValue returns error for HKLM"
  EnVar::SetHKLM
  EnVar::AddValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  EnVar::SetHKCU
	${TestEnd} ${ERR_NOWRITE}
  !endif

  ${TestStart} "AddValue returns success if path added"
  EnVar::AddValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  Push $0
  ReadRegStr $0 HKCU "Environment" "NsisEnVarTestVariable"
  StrCmp $0 "C:\NsisEnVarTestPath" AddValueEnd
  ${IncError}
  ${LogMessage} 'FAILED AddValue write value'
  AddValueEnd:
  Pop $0
	${TestEnd} ${ERR_SUCCESS}

	${TestStart} "AddValue returns success if path found"
  EnVar::AddValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
	${TestEnd} ${ERR_SUCCESS}

  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
SectionEnd

Section "Test EnVar::AddValueEx"
	${TestStart} "AddValueEx returns error for empty path"
  EnVar::AddValueEx "NsisEnVarTestVariable" ""
	${TestEnd} ${ERR_NOVALUE}

  !ifdef RISKY
	${TestStart} "AddValueEx returns error for HKLM"
  EnVar::SetHKLM
  EnVar::AddValueEx "NsisEnVarTestVariable" "NsisEnVarTestVariable"
  EnVar::SetHKCU
	${TestEnd} ${ERR_NOWRITE}
  !endif

  ${TestStart} "AddValueEx returns success if path added"
  EnVar::AddValueEx "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  Push $0
  ReadRegStr $0 HKCU "Environment" "NsisEnVarTestVariable"
  StrCmp $0 "C:\NsisEnVarTestPath" AddValueExEnd
  ${IncError}
  ${LogMessage} 'FAILED AddValueEx write value'
  AddValueExEnd:
  Pop $0
	${TestEnd} ${ERR_SUCCESS}

	${TestStart} "AddValueEx returns success if path found"
  EnVar::AddValueEx "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
	${TestEnd} ${ERR_SUCCESS}

  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
SectionEnd

Section "Test EnVar::DeleteValue"
	${TestStart} "DeleteValue returns error for non existing variable"
  EnVar::DeleteValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
	${TestEnd} ${ERR_NOVARIABLE}

	${TestStart} "DeleteValue returns error for non existing path"
  WriteRegStr HKCU "Environment" "NsisEnVarTestVariable" ""
  EnVar::DeleteValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
	${TestEnd} ${ERR_NOVALUE}

	${TestStart} "DeleteValue returns success"
  WriteRegStr HKCU "Environment" "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  EnVar::DeleteValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"
  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
	${TestEnd} ${ERR_SUCCESS}

  !ifdef RISKY
	${TestStart} "DeleteValue returns error if variable not writeable"
  EnVar::SetHKLM
  EnVar::DeleteValue "windir" "%SystemRoot%"
  EnVar::SetHKCU
	${TestEnd} ${ERR_NOWRITE}
  !endif
SectionEnd

Section "Test EnVar::Delete"
	${TestStart} "Delete returns error for path"
  EnVar::Delete "path"
	${TestEnd} ${ERR_NOWRITE}

  WriteRegStr HKCU "Environment" "NsisEnVarTestVariable" ""

	${TestStart} "Delete returns success"
  EnVar::Delete "NsisEnVarTestVariable"
	${TestEnd} ${ERR_SUCCESS}

  ClearErrors
  ReadRegStr $0 HKCU "Environment" "NsisEnVarTestVariable"
  IfErrors DeleteEnd 0
  ${IncError}
  ${LogMessage} 'FAILED Delete deletes key'
  DeleteEnd:

  !ifdef RISKY
	${TestStart} "Delete returns error if variable not writeable"
  EnVar::SetHKLM
  EnVar::Delete "windir"
  EnVar::SetHKCU
	${TestEnd} ${ERR_NOWRITE}
  !endif
SectionEnd

Section "Test EnVar::Update"
  Var /GLOBAL PreValue
  Var /GLOBAL PostValue

  ReadEnvStr $PreValue "NsisEnVarTestVariable"
  ClearErrors
  WriteRegStr HKCU "Environment" "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"

	${TestStart} "Update properly updates variable"
  EnVar::Update "HKCU" "NsisEnVarTestVariable"
	${TestEnd} ${ERR_SUCCESS}

  ReadEnvStr $PostValue "NsisEnVarTestVariable"
  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"

  StrCmp $PreValue $PostValue 0 UpdateEnd
  ${IncError}
  ${LogMessage} 'FAILED Update did not update variable'
  UpdateEnd:
SectionEnd

Section "Test large strings"
  IntOp $Counter 0 * 0

  WriteRegStr HKCU "Environment" "NsisEnVarTestVariable" "C:\NsisEnVarTestPath"

	${TestStart} "Add paths up to upper limit"
  loop1:
  IntFmt $CounterFormatted "%04X" $Counter
  EnVar::AddValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath123456x$CounterFormatted"
  Pop $CounterFormatted
  IntOp $Counter $Counter + 32
  IntCmp $Counter 32000 loop1 loop1 +1
  #IntCmp $Counter 16300 loop1 loop1 +1

  Push "0"
	${TestEnd} ${ERR_SUCCESS}

	${TestStart} "Remove added paths"
  loop2:
  IntFmt $CounterFormatted "%04X" $Counter
  EnVar::DeleteValue "NsisEnVarTestVariable" "C:\NsisEnVarTestPath123456x$CounterFormatted"
  Pop $CounterFormatted
  IntOp $Counter $Counter - 32
  IntCmp $Counter 0 loop2 +1 loop2

  Push "0"
	${TestEnd} ${ERR_SUCCESS}

	${TestStart} "Test variable is empty"
  ReadRegStr $Counter HKCU "Environment" "NsisEnVarTestVariable"
  StrCmp $Counter "C:\NsisEnVarTestPath" +4

  ${IncError}
  Push $Counter
  Goto +2

  Push "0"
	${TestEnd} ${ERR_SUCCESS}

  DeleteRegValue HKCU "Environment" "NsisEnVarTestVariable"
SectionEnd

Section "Check for errors"
  IntCmpU $ErrorCount 0 CheckSucceeded

  SetErrorLevel 3
  ${LogMessage} "Tests FAILED with $ErrorCount errors"
  Goto CheckEnd

  CheckSucceeded:
  ${LogMessage} "Tests SUCCEEDED"

  CheckEnd:
  FileClose $LogFile
SectionEnd
