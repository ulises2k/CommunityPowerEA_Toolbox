# ToolBox for CP
#
# Autor: Ulises Cune (@Ulises2k)
#
#
# !!!! It version is for CommunityPower EA !!!!
#
#
# Windows 2008
# Set-ExecutionPolicy RemoteSigned
#
# Windows 2008
# Set-ExecutionPolicy Restricted
#
#RUN, open "cmd.exe" and write this:
#powershell -ExecutionPolicy Bypass -File "CommunityPowerEA_MyDefault.ps1"
#
#
Function Get-IniFile {
    Param(
        [string]$FilePath
    )
    $ini = [ordered]@{}
    switch -regex -file $FilePath {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $ini[$name] = $value.Split('||')[0]
                    continue
                }
                else {
                    $ini[$name] = $value
                    continue
                }
            }
        }
    }
    $ini
}

function StopProcessNotPermitWriteParam {
    Param(
        [string]$nameProcesss
    )
    $statusDropBox = Get-Process -Name $nameProcesss -ErrorAction SilentlyContinue
    if ($null -ne $statusDropBox) {
        Stop-Process -Name $nameProcesss
    }
}

function Set-OrAddIniValue {
    Param(
        [string]$FilePath,
        [hashtable]$keyValueList
    )
    $content = Get-Content $FilePath
    $keyValueList.GetEnumerator() | ForEach-Object {
        if ($content -match "^$($_.Key)=") {
            $content = $content -replace "^$($_.Key)=(.*)", "$($_.Key)=$($_.Value)"
        }
        else {
            $content += "$($_.Key)=$($_.Value)"
        }
    }

    StopProcessNotPermitWriteParam -nameProcesss "dropbox"

    $content | Set-Content $FilePath
}


#Deshabilita las opciones que no corresponden
function IndicatorIfNotValidOption {
    Param(
        [string]$FilePath,
        [string]$indy,
        [string]$EnableTypeMode
    )

    #Read All Setting File parameters
    $inifile = Get-IniFile -FilePath $FilePath

    #If not select Open/OpenMartin/Close/Partial Disable
    $OpenOn = [int]$inifile[$indy + "_OpenOn"]
    $MartinOn = [int]$inifile[$indy + "_MartinOn"]
    $HedgeOn = [int]$inifile[$indy + "_HedgeOn"]
    $CloseOn = [int]$inifile[$indy + "_CloseOn"]
    $PartialCloseOn = [int]$inifile[$indy + "_PartialCloseOn"]

    if (($OpenOn -eq 0) -and ($MartinOn -eq 0) -and ($HedgeOn -eq 0) -and ($CloseOn -eq 0) -and ($PartialCloseOn -eq 0)) {

        if ($EnableTypeMode -eq "Type") {
            $EnableTypeMode_Value = "0"
        }
        if ($EnableTypeMode -eq "Enable") {
            $EnableTypeMode_Value = "false"
        }
        if ($EnableTypeMode -eq "Mode") {
            $EnableTypeMode_Value = "0"
        }

        $IndyType = $indy + "_" + $EnableTypeMode
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            $IndyType = $EnableTypeMode_Value
        }
    }


    #If not Enabled, Don't use for open/Don't use for close/Don't use for partial close
    $indyname = $indy + "_" + $EnableTypeMode
    $EnableTypeMode = [string]$inifile[$indyname]
    if (($EnableTypeMode -eq "0") -or ($EnableTypeMode -eq "false")) {
        $Indy_Open = $indy + "_OpenOn"
        $Indy_MartinOn = $indy + "_MartinOn"
        $Indy_HedgeOn = $indy + "_HedgeOn"
        $Indy_CloseOn = $indy + "_CloseOn"
        $Indy_PartialCloseOn = $indy + "_PartialCloseOn"
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            $Indy_Open           = "0"
            $Indy_MartinOn       = "0"
            $Indy_HedgeOn        = "0"
            $Indy_CloseOn        = "0"
            $Indy_PartialCloseOn = "0"
        }
    }
}


# Detecta si la estrategia es GRID
function DetectGRID {
    Param(
        [string]$Filepath,
        [string]$indy
    )

    #Read All Setting File parameters
    $inifile = Get-IniFile -FilePath $FilePath

    $GRID = $false

    #If not select Open/OpenMartin/Close/Partial Disable
    $OpenOn = [int]$inifile[$indy + "_OpenOn"]
    $MartinOn = [int]$inifile[$indy + "_MartinOn"]
    $CloseOn = [int]$inifile[$indy + "_CloseOn"]
    $PartialCloseOn = [int]$inifile[$indy + "_PartialCloseOn"]
    $HedgeOn = [int]$inifile[$indy + "_HedgeOn"]
    if (($OpenOn -eq 0) -and ($MartinOn -eq 0) -and ($CloseOn -eq 0) -and ($PartialCloseOn -eq 0) -and ($HedgeOn -eq 0)) {
        $GRID = $true
    }

    $Indy_Type = [int]$inifile[$indy + "_Type"]
    if ($Indy_Type -eq 0) {
        $GRID = $true
    }
    $Indy_Enable = [string]$inifile[$indy + "_Enable"]
    if ($Indy_Enable -eq "0") {
        $GRID = $true
    }
    $Indy_Mode = [string]$inifile[$indy + "_Mode"]
    if ($Indy_Mode -eq "false") {
        $GRID = $true
    }

    return $GRID
}

#Convertir una estrategia basada en indicadores a GRID
function ConvertToGRID {
    Param(
        [string]$Filepath,
        [string]$indy
    )

    #If not Enabled, Don't use for open/Don't use for close/Don't use for partial close
    $Indy_Open = $indy + "_OpenOn"
    $Indy_MartinOn = $indy + "_MartinOn"
    $Indy_CloseOn = $indy + "_CloseOn"
    $Indy_PartialCloseOn = $indy + "_PartialCloseOn"
    $Indy_HedgeOn = $indy + "_HedgeOn"
    Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
        $Indy_Open           = "0"
        $Indy_MartinOn       = "0"
        $Indy_CloseOn        = "0"
        $Indy_PartialCloseOn = "0"
        $Indy_HedgeOn        = "0"
    }

    if ($indy -eq "IdentifyTrend"){
        Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
            "IdentifyTrend_Enable" = "false"
        }
    }
    elseif ($indy -eq "TDI"){
        Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
            "TDI_Mode" = "0"
        }
    }
    else{
        $indy_Type = $indy + "_Type"
        Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
            $indy_Type = "0"
        }
    }

}

#Todos los indicadores que se puede construir con las Media Moviles
function IndicatorsWithMA {
    Param(
        [string]$FilePath,
        [string]$Name,
        [string]$Number,
        [string]$Filter_Type,
        [string]$Filter_Period,
        [string]$Filter_Method,
        [string]$Filter_Price,
        [string]$Filter_DistType,
        [string]$Filter_DistCoef,
        [string]$Filter_OpenOn,
        [string]$Filter_CloseOn,
        [string]$VolMA_Type,
        [string]$VolMA_Period
    )

    $MA_Filter_Properties = "MA_Filter_" + $Number + "_Properties"
    $MA_Filter_Type = "MA_Filter_" + $Number + "_Type"
    #$MA_Filter_TF = "MA_Filter_" + $Number + "_TF"
    $MA_Filter_Period = "MA_Filter_" + $Number + "_Period"
    $MA_Filter_Method = "MA_Filter_" + $Number + "_Method"
    $MA_Filter_Price = "MA_Filter_" + $Number + "_Price"
    $MA_Filter_DistType = "MA_Filter_" + $Number + "_DistType"
    $MA_Filter_DistCoef = "MA_Filter_" + $Number + "_DistCoef"
    #$MA_Filter_OpenOn = "MA_Filter_" + $Number + "_OpenOn"
    #$MA_Filter_MartinOn = "MA_Filter_" + $Number + "_MartinOn"
    #$MA_Filter_CloseOn = "MA_Filter_" + $Number + "_CloseOn"
    #$MA_Filter_PartialCloseOn = "MA_Filter_" + $Number + "_PartialCloseOn"

    #2.51.(2/5/6/7)(Beta)
    #$MA_Filter_ActivePeriod = "MA_Filter_" + $Number + "_ActivePeriod"

    #2.53
    $MA_Filter_Reverse = "MA_Filter_" + $Number + "_Reverse"
    $MA_Filter_UseClosedBars = "MA_Filter_" + $Number + "_UseClosedBars"

    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
        $MA_Filter_Properties     = "===== " + $Name + " #" + $Number + " ====="
        $MA_Filter_Type           = $Filter_Type
        #$MA_Filter_TF             = "5"
        $MA_Filter_Period         = $Filter_Period
        $MA_Filter_Method         = $Filter_Method
        $MA_Filter_Price          = $Filter_Price
        $MA_Filter_DistType       = $Filter_DistType
        $MA_Filter_DistCoef       = $Filter_DistCoef
        #$MA_Filter_OpenOn         = $Filter_OpenOn
        #$MA_Filter_MartinOn       = "0"
        #$MA_Filter_CloseOn        = $Filter_CloseOn
        #$MA_Filter_PartialCloseOn = "0"
        #$MA_Filter_ActivePeriod   = "0"
    }

    #2.53
    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
        $MA_Filter_Reverse       = "false"
        $MA_Filter_UseClosedBars = "false"
    }

    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
        VolMA_Properties = "===== Volatility for " + $Name + " #" + $Number + " ====="
        VolMA_Type       = $VolMA_Type
        #VolMA_TF         = "5"
        VolMA_Period     = $VolMA_Period
    }
}

#
#Correlaciones
#https://www.mataf.net/es/forex/tools/correlation
#
#; My Defaults
function MyDefault {
    Param(
        [string]$FilePath
    )

    if (!(Test-Path -Path "$FilePath")) {
        return [bool]$false, 'Cant copy file. Reduce the PATH: $CurrentDir . Move the file, for example to C:\temp'
    }

    Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
        BinanceTradeConnector_Settings = "===== Binance ====="
        Expert_Properties              = "===== Expert ====="
        Expert_Id                      = "253"
        Expert_Comment                 = "CP" + (Get-Date -Format "dd.MM.yyyy.HH:mm")
        Lot_Properties                 = "===== Lot ====="
        Hedge_Properties               = "===== Hedge ====="
        GlobalAccount_Properties       = "===== Global Account ====="
        DL_Properties                  = "===== Daily limits ====="
        WL_Properties                  = "===== Weekly limits ====="
        ML_Properties                  = "===== Monthly limits ====="
        CL_Properties                  = "===== Common limits properties ====="
        VolPV_Properties               = "===== Volatility for all parameters nominated in points ====="
        ActivePeriods_Properties       = "===== Active Periods for signals and filters ====="
        ActivePeriod_1                 = "===== Active Period 1 ====="
        ActivePeriod_2                 = "===== Active Period 2 ====="
        ActivePeriod_3                 = "===== Active Period 3 ====="
        ActivePeriod_4                 = "===== Active Period 4 ====="
        Pending_Properties             = "===== Pending entry ====="
        StopLoss_Properties            = "===== Stop Loss ====="
        StopLoss_Global                = "===== Sum Stop Loss (buy + sell) ====="
        StopLoss_Pause                 = "===== Pause after loss ====="
        #UseVirtualSL                   = "false"
        VirtualSL                      = "===== Virtual StopLoss ====="
        VirtualTP                      = "===== Virtual TakeProfit ====="
        TakeProfit_Properties          = "===== Take Profit ====="
        TakeProfit_ReduceAfter         = "===== Reduce Take Profit after minutes ====="
        TakeProfit_ReduceSeries        = "===== Reduce Take Profit for every order ====="
        TakeProfit_Global              = "===== Sum Take Profit (buy + sell) ====="
        MinProfitToClose_Properties    = "===== Min profit to close on signal ====="
        #UseVirtualTP                   = "false"
        BreakEven_Properties           = "===== BreakEven ====="
    }

    Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
        RiskPerCurrency_Properties  = "===== Risk per currency ====="
        TrailingStop_Properties     = "===== Trailing Stop ====="
        Martingale_Properties       = "===== Martingale ====="
        BE_Alert_After              = "6"
        AllowBoth_Properties        = "===== Allow both Martin and Anti-martin ====="
        PartialClose_Properties     = "===== Partial Close ====="
        GlobalMartingail_Properties = "===== Apply martin to the new deals ====="
        AntiMartingale_Properties   = "===== Anti-Martingale ====="
        Individual_Properties       = "===== Individual Order ====="
    }

    Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
        DirChange_Properties     = "===== Directional Change ====="
        BigCandle_Properties     = "===== Big Candle ====="
        Oscillators_Properties   = "===== Oscillator #1 ====="
        Oscillator2_Properties   = "===== Oscillator #2 ====="
        Oscillator3_Properties   = "===== Oscillator #3 ====="
        IdentifyTrend_Properties = "===== IdentifyTrend ====="
        TDI_Properties           = "===== TDI ====="
        MACD_Properties          = "===== MACD #1 ====="
        MACD2_Properties         = "===== MACD #2 ====="
        ADX_Properties           = "===== ADX ====="
        DTrend_Properties        = "===== DTrend ====="
        PSar_Properties          = "===== Parabolic SAR ====="
        MA_Filter_1_Properties   = "===== MA Filter #1 ====="
        MA_Filter_2_Properties   = "===== MA Filter #2 ====="
        MA_Filter_3_Properties   = "===== MA Filter #3 ====="
        ZZ_Properties            = "===== ZigZag ====="
        VolMA_Properties         = "===== Volatility for MA and ZigZag Filters distance ====="
        VolFilter_Properties     = "===== Volatility Filter ====="
        FIBO_Properties          = "===== FIBO #1 ====="
        FIB2_Properties          = "===== FIBO #2 ====="
        MACDF_Properties         = "===== MACD for FIBO signals ====="
        CustomIndy1_Properties   = "===== Custom Indy #1 ====="
        CustomIndy2_Properties   = "===== Custom Indy #2 ====="
        CustomIndy3_Properties   = "===== Custom Indy #3 ====="
    }

    Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
        Spread_Settings            = "===== Spread ====="
        Time_Settings              = "===== Time ====="
        Time_DST_Mode              = "1"
        Time_Manual_GMT_Offset     = "2"
        Custom_Schedule_Properties = "===== Custom Schedule ====="
        NewYear_Properties         = "===== New Year Holidays ====="
        News_Properties            = "===== News ====="
        News_Draw_Properties       = "===== Visualization ====="
        Lines_Settings             = "===== Lines ====="
        NextOrder_Width            = "1"
        NextOrder_Style            = "2"
        NextOrder_ColorB           = "65280"
        NextOrder_ColorS           = "255"
        StopLoss_Width             = "2"
        StopLoss_Style             = "1"
        StopLoss_ColorB            = "5737262"
        StopLoss_ColorS            = "1993170"
        BreakEven_Width            = "2"
        BreakEven_Style            = "0"
        TakeProfit_ColorB          = "65280"
        TakeProfit_ColorS          = "255"
        GUI_Settings               = "===== GUI ====="
        ManageManual               = "true"
        GUI_Enabled                = "true"
        ShowOrders_Settings        = "===== Show Orders ====="
        Show_Opened                = "1"
        Show_Closed                = "true"
        TakeProfit_Width           = "2"
        TakeProfit_Style           = "4"
        BreakEven_ColorB           = "3329330"
        BreakEven_ColorS           = "17919"
        MaxHistoryDeals            = "10"
    }

    Set-OrAddIniValue -FilePath $FilePath -keyValueList @{
        Color_Properties       = "===== Main Color ====="
        Profit_Properties      = "===== Profit ====="
        Profit_ShowInMoney     = "true"
        Profit_ShowInPoints    = "true"
        Profit_ShowInPercents  = "true"
        Profit_Aggregate       = "true"
        ProfitDigitsToShow     = "2"
        Style_Properties       = "===== Style ====="
        Open_Close_Line_Width  = "1"
        Open_Close_Line_Style  = "2"
        Open_PriceLabel_Width  = "1"
        Close_PriceLabel_Width = "1"
        SL_TP_Dashes_Show      = "true"
        SL_TP_Lines_Width      = "0"
        SL_TP_Lines_Style      = "2"
        Expiration_Width       = "1"
        Expiration_Style       = "2"
        Notifications_Settings = "===== Notifications ====="
        MessagesToGrammy       = "false"
        Alerts_Enabled         = "false"
        Sounds_Enabled         = "false"
        Optimization_Settings  = "===== Optimization ====="
    }

    #Read All Setting File parameters
    $inifile = Get-IniFile -FilePath $FilePath

    #Detect Exist a Custom Indicator. Version => 2.49.2.1(BETA)
    $CustomIndy1_Type = [int]$inifile["CustomIndy1_Type"]
    if ($CustomIndy1_Type -ne 0) {
        $CustomIndy1_DrawShortName = [string]$inifile["CustomIndy1_DrawShortName"]
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            CustomIndy1_Properties = "===== " + $CustomIndy1_DrawShortName + " ====="
        }
    }
    $CustomIndy2_Type = [int]$inifile["CustomIndy2_Type"]
    if ($CustomIndy2_Type -ne 0) {
        $CustomIndy2_DrawShortName = [string]$inifile["CustomIndy2_DrawShortName"]
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            CustomIndy2_Properties = "===== " + $CustomIndy2_DrawShortName + " ====="
        }
    }
    $CustomIndy3_Type = [int]$inifile["CustomIndy3_Type"]
    if ($CustomIndy3_Type -ne 0) {
        $CustomIndy3_DrawShortName = [string]$inifile["CustomIndy3_DrawShortName"]
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            CustomIndy3_Properties = "===== " + $CustomIndy3_DrawShortName + " ====="
        }
    }


    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "DisableTime" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day ====="
                EveryDay_StartHour         = "-1"
                EveryDay_StartMinute       = "0"
                EveryDay_EndHour           = "-1"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday ====="
                FridayStop_Hour            = "-1"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "-1"
                MondayStart_Minute         = "0"
                Custom_Schedule_Properties = "===== Custom Schedule ====="
                Monday_StartHour           = "-1"
                Monday_StartMinute         = "0"
                Monday_EndHour             = "-1"
                Monday_EndMinute           = "0"
                Tuesday_StartHour          = "-1"
                Tuesday_StartMinute        = "0"
                Tuesday_EndHour            = "-1"
                Tuesday_EndMinute          = "0"
                Wednesday_StartHour        = "-1"
                Wednesday_StartMinute      = "0"
                Wednesday_EndHour          = "-1"
                Wednesday_EndMinute        = "0"
                Thursday_StartHour         = "-1"
                Thursday_StartMinute       = "0"
                Thursday_EndHour           = "-1"
                Thursday_EndMinute         = "0"
                Friday_StartHour           = "-1"
                Friday_StartMinute         = "0"
                Friday_EndHour             = "-1"
                Friday_EndMinute           = "0"
            }
        }
    }

    #http://www.timezoneconverter.com/cgi-bin/zoneinfo
    #
    #https://forex.timezoneconverter.com/?timezone=Europe/Helsinki;
    #
    #https://www.compareforexbrokers.com/forex-trading/hours/
    #
    #OVERLAPS – BEST TIMES TO TRADE THE FOREX MARKET?
    #https://forexboat.com/forex-trading-hours/
    #
    #https://drive.google.com/drive/folders/1N0ksZWjYVLWVBiWR8wBkScewmOg3Jv6X
    #GMT+2 (Europe/Helsinki)
    #https://drive.google.com/file/d/1GpbCap8Etmxl2IcvC6oExe_U06m8Svw4/view?usp=sharing
    #
    #https://roboforex.com/beginners/info/forex-trading-hours/
    #ASIA
    #Tokyo      2:00    10:00 (Europe/Helsinki)
    #Hong Kong  3:00    11:00
    #Singapore  2:00    10:00
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "ASIA(Tokyo/Hong Kong/Singapore)" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / ASIA ====="
                EveryDay_StartHour         = "2"
                EveryDay_StartMinute       = "0"
                EveryDay_EndHour           = "10"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday ====="
                FridayStop_Hour            = "-1"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "-1"
                MondayStart_Minute         = "0"
                Custom_Schedule_Properties = "===== Custom Schedule ====="
                Monday_StartHour           = "-1"
                Monday_StartMinute         = "0"
                Monday_EndHour             = "-1"
                Monday_EndMinute           = "0"
                Tuesday_StartHour          = "-1"
                Tuesday_StartMinute        = "0"
                Tuesday_EndHour            = "-1"
                Tuesday_EndMinute          = "0"
                Wednesday_StartHour        = "-1"
                Wednesday_StartMinute      = "0"
                Wednesday_EndHour          = "-1"
                Wednesday_EndMinute        = "0"
                Thursday_StartHour         = "-1"
                Thursday_StartMinute       = "0"
                Thursday_EndHour           = "-1"
                Thursday_EndMinute         = "0"
                Friday_StartHour           = "-1"
                Friday_StartMinute         = "0"
                Friday_EndHour             = "-1"
                Friday_EndMinute           = "0"
            }
        }
    }

    #Europa
    #Frankfurt  9:00    17:00
    #London     10:00   18:00 (Europe/Helsinki)
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "EUROPA(Frankfurt/London)" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / EUROPA ====="
                EveryDay_StartHour         = "9"
                EveryDay_StartMinute       = "0"
                EveryDay_EndHour           = "18"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday ====="
                FridayStop_Hour            = "-1"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "-1"
                MondayStart_Minute         = "0"
                Custom_Schedule_Properties = "===== Custom Schedule ====="
                Monday_StartHour           = "-1"
                Monday_StartMinute         = "0"
                Monday_EndHour             = "-1"
                Monday_EndMinute           = "0"
                Tuesday_StartHour          = "-1"
                Tuesday_StartMinute        = "0"
                Tuesday_EndHour            = "-1"
                Tuesday_EndMinute          = "0"
                Wednesday_StartHour        = "-1"
                Wednesday_StartMinute      = "0"
                Wednesday_EndHour          = "-1"
                Wednesday_EndMinute        = "0"
                Thursday_StartHour         = "-1"
                Thursday_StartMinute       = "0"
                Thursday_EndHour           = "-1"
                Thursday_EndMinute         = "0"
                Friday_StartHour           = "-1"
                Friday_StartMinute         = "0"
                Friday_EndHour             = "-1"
                Friday_EndMinute           = "0"
            }
        }
    }

    #América
    #New York   15:00   23:00 (Europe/Helsinki)
    #Chicago    16:00   24:00
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "AMERICA(New York/Chicago)" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / AMERICA ====="
                EveryDay_StartHour         = "15"
                EveryDay_StartMinute       = "0"
                EveryDay_EndHour           = "24"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday ====="
                FridayStop_Hour            = "-1"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "-1"
                MondayStart_Minute         = "0"
                Custom_Schedule_Properties = "===== Custom Schedule ====="
                Monday_StartHour           = "-1"
                Monday_StartMinute         = "0"
                Monday_EndHour             = "-1"
                Monday_EndMinute           = "0"
                Tuesday_StartHour          = "-1"
                Tuesday_StartMinute        = "0"
                Tuesday_EndHour            = "-1"
                Tuesday_EndMinute          = "0"
                Wednesday_StartHour        = "-1"
                Wednesday_StartMinute      = "0"
                Wednesday_EndHour          = "-1"
                Wednesday_EndMinute        = "0"
                Thursday_StartHour         = "-1"
                Thursday_StartMinute       = "0"
                Thursday_EndHour           = "-1"
                Thursday_EndMinute         = "0"
                Friday_StartHour           = "-1"
                Friday_StartMinute         = "0"
                Friday_EndHour             = "-1"
                Friday_EndMinute           = "0"
            }
        }
    }

    #Pacífico
    #Sidney     1:00    9:00 (Europe/Helsinki)
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "PACIFICO(Wellington/Sidney)" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / PACIFICO ====="
                EveryDay_StartHour         = "1"
                EveryDay_StartMinute       = "0"
                EveryDay_EndHour           = "9"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday ====="
                FridayStop_Hour            = "-1"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "-1"
                MondayStart_Minute         = "0"
                Custom_Schedule_Properties = "===== Custom Schedule ====="
                Monday_StartHour           = "-1"
                Monday_StartMinute         = "0"
                Monday_EndHour             = "-1"
                Monday_EndMinute           = "0"
                Tuesday_StartHour          = "-1"
                Tuesday_StartMinute        = "0"
                Tuesday_EndHour            = "-1"
                Tuesday_EndMinute          = "0"
                Wednesday_StartHour        = "-1"
                Wednesday_StartMinute      = "0"
                Wednesday_EndHour          = "-1"
                Wednesday_EndMinute        = "0"
                Thursday_StartHour         = "-1"
                Thursday_StartMinute       = "0"
                Thursday_EndHour           = "-1"
                Thursday_EndMinute         = "0"
                Friday_StartHour           = "-1"
                Friday_StartMinute         = "0"
                Friday_EndHour             = "-1"
                Friday_EndMinute           = "0"
            }
        }
    }

    #DateTime-EUR/USD Time
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "DateTime-EUR/USD" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / EUR/USD ====="
                EveryDay_StartHour         = "0"
                EveryDay_StartMinute       = "5"
                EveryDay_EndHour           = "23"
                EveryDay_EndMinute         = "45"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday / EUR/USD ====="
                FridayStop_Hour            = "22"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "0"
                MondayStart_Minute         = "5"
                Custom_Schedule_Properties = "===== Custom Schedule / EUR/USD ====="
                Monday_StartHour           = "0"
                Monday_StartMinute         = "5"
                Monday_EndHour             = "23"
                Monday_EndMinute           = "45"
                Tuesday_StartHour          = "0"
                Tuesday_StartMinute        = "5"
                Tuesday_EndHour            = "23"
                Tuesday_EndMinute          = "50"
                Wednesday_StartHour        = "0"
                Wednesday_StartMinute      = "5"
                Wednesday_EndHour          = "23"
                Wednesday_EndMinute        = "45"
                Thursday_StartHour         = "0"
                Thursday_StartMinute       = "5"
                Thursday_EndHour           = "23"
                Thursday_EndMinute         = "45"
                Friday_StartHour           = "0"
                Friday_StartMinute         = "5"
                Friday_EndHour             = "22"
                Friday_EndMinute           = "0"
            }
        }
    }

    #DateTime-XAU/USD Time
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "DateTime-XAU/USD" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / XAU/USD ====="
                EveryDay_StartHour         = "1"
                EveryDay_StartMinute       = "5"
                EveryDay_EndHour           = "23"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday / XAU/USD ====="
                FridayStop_Hour            = "22"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "0"
                MondayStart_Minute         = "5"
                Custom_Schedule_Properties = "===== Custom Schedule / XAU/USD ====="
                Monday_StartHour           = "1"
                Monday_StartMinute         = "5"
                Monday_EndHour             = "23"
                Monday_EndMinute           = "45"
                Tuesday_StartHour          = "1"
                Tuesday_StartMinute        = "5"
                Tuesday_EndHour            = "23"
                Tuesday_EndMinute          = "45"
                Wednesday_StartHour        = "1"
                Wednesday_StartMinute      = "5"
                Wednesday_EndHour          = "22"
                Wednesday_EndMinute        = "0"
                Thursday_StartHour         = "1"
                Thursday_StartMinute       = "5"
                Thursday_EndHour           = "23"
                Thursday_EndMinute         = "45"
                Friday_StartHour           = "1"
                Friday_StartMinute         = "5"
                Friday_EndHour             = "22"
                Friday_EndMinute           = "0"
                News_Properties            = "===== News / XAU/USD ====="
                News_Currencies            = "auto"
                News_Impact_H              = "true"
                News_Impact_M              = "true"
                News_Impact_L              = "false"
                News_Impact_N              = "false"
                News_FilterInclude         = "Fed,Employment,PIB,NFP,BCE"
                News_MinutesBefore         = "30"
                News_MinutesAfter          = "30"
            }
        }
    }

    #MyDefault-EUR/USD Time
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "MyDefault-EUR/USD" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / EUR/USD ====="
                EveryDay_StartHour         = "0"
                EveryDay_StartMinute       = "5"
                EveryDay_EndHour           = "23"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday / EUR/USD ====="
                FridayStop_Hour            = "22"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "0"
                MondayStart_Minute         = "5"
                Custom_Schedule_Properties = "===== Custom Schedule / EUR/USD ====="
                Monday_StartHour           = "0"
                Monday_StartMinute         = "5"
                Monday_EndHour             = "23"
                Monday_EndMinute           = "45"
                Tuesday_StartHour          = "0"
                Tuesday_StartMinute        = "5"
                Tuesday_EndHour            = "23"
                Tuesday_EndMinute          = "45"
                Wednesday_StartHour        = "0"
                Wednesday_StartMinute      = "5"
                Wednesday_EndHour          = "23"
                Wednesday_EndMinute        = "45"
                Thursday_StartHour         = "0"
                Thursday_StartMinute       = "5"
                Thursday_EndHour           = "23"
                Thursday_EndMinute         = "45"
                Friday_StartHour           = "0"
                Friday_StartMinute         = "5"
                Friday_EndHour             = "22"
                Friday_EndMinute           = "0"
            }
        }
    }

    #Default-AUD/USD Time
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "Default-AUD/USD" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                EveryDay_Properties        = "===== Every Day / AUD/USD ====="
                EveryDay_StartHour         = "21"
                EveryDay_StartMinute       = "0"
                EveryDay_EndHour           = "6"
                EveryDay_EndMinute         = "0"
                EveryDay_CloseHour         = "-1"
                EveryDay_CloseMinute       = "0"
                FridayMonday_Properties    = "===== Friday and Monday / AUD/USD ====="
                FridayStop_Hour            = "-1"
                FridayStop_Minute          = "0"
                FridayClose_Hour           = "-1"
                FridayClose_Minute         = "0"
                MondayStart_Hour           = "-1"
                MondayStart_Minute         = "0"
                Custom_Schedule_Properties = "===== Custom Schedule / AUD/USD ====="
                Monday_StartHour           = "-1"
                Monday_StartMinute         = "0"
                Monday_EndHour             = "-1"
                Monday_EndMinute           = "0"
                Tuesday_StartHour          = "-1"
                Tuesday_StartMinute        = "0"
                Tuesday_EndHour            = "-1"
                Tuesday_EndMinute          = "0"
                Wednesday_StartHour        = "-1"
                Wednesday_StartMinute      = "0"
                Wednesday_EndHour          = "-1"
                Wednesday_EndMinute        = "0"
                Thursday_StartHour         = "-1"
                Thursday_StartMinute       = "0"
                Thursday_EndHour           = "-1"
                Thursday_EndMinute         = "0"
                Friday_StartHour           = "-1"
                Friday_StartMinute         = "0"
                Friday_EndHour             = "-1"
                Friday_EndMinute           = "0"
            }
        }
    }

    #News Critical
    if (!($comboBox.SelectedIndex -eq "-1")) {
        if ($comboBox.SelectedItem.ToString() -eq "No Traded On Critical News" ) {
            Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
                # ; News settings
                News_Properties     = "===== News ====="
                News_Mode           = "2"
                News_Currencies     = "auto"
                News_Impact_H       = "true"
                News_Impact_M       = "true"
                News_Impact_L       = "false"
                News_Impact_N       = "false"
                News_FilterInclude  = "Fed,Employment,PIB,NFP,BCE,FOMC,CPI,PMI,BOC"
                News_MinutesBefore  = "120"
                News_MinutesAfter   = "60"
                News_OpenOn         = "2"
                News_MartinOn       = "0"
                News_CloseOn        = "2"
                News_PartialCloseOn = "0"
            }
        }
    }
    #Read All Setting File parameters
    $inifile = Get-IniFile($FilePath)

    #Pending_Type
    #$Pending_Type = [int]$inifile["Pending_Type"]
    #if ($Pending_Type -eq 0) {
    #    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
    #        Show_Pending    = "false"
    #    }
    #}
    #else {
    #    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
    #        Show_Pending    = "true"
    #    }
    #}

    #If not use StopLoss disable line
    #$StopLoss = [int]$inifile["StopLoss"]
    #$GlobalStopLoss = [int]$inifile["GlobalStopLoss"]
    #$GlobalStopLoss_ccy = [int]$inifile["GlobalStopLoss_ccy"]
    #if (($StopLoss -eq 0) -and ($GlobalStopLoss -eq 0) -and ($GlobalStopLoss_ccy -eq 0)) {
    #    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
    #        StopLoss_Width = "0"
    #    }
    #}
    #else {
    #    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
    #        StopLoss_Width = "2"
    #    }
    #}


    #The stop level: This can be considered as a normal stop loss. When you add a trailing stop to an open position, your trailing stop is not active immediately. The market needs to move in your favour by the step distance for the trailing stop to be activated. If the market moves far enough against you before your trailing stop is activated, your position will be closed at this stop level.
    #The stop distance: This will be the distance between your trailing stop and the market level once your trailing stop is activated. The trailing stop will maintain this stop distance as it tracks the market.
    #The step distance: This is the number of points the market needs to move in your favour for the trailing stop to be adjusted upward or downward, depending on whether you are going long or short.
    #ATR disable is not used
    $Pending_Distance_ModeP = [int]$inifile["Pending_Distance_ModeP"]
    $StopLoss_ModeP = [int]$inifile["StopLoss_ModeP"]
    $TakeProfit_ModeP = [int]$inifile["TakeProfit_ModeP"]
    $MinProfitToClose_ModeP = [int]$inifile["MinProfitToClose_ModeP"]
    $TrailingStop_ModeP = [int]$inifile["TrailingStop_ModeP"]
    $Martingail_ModeP = [int]$inifile["Martingail_ModeP"]
    $AntiMartingail_ModeP = [int]$inifile["AntiMartingail_ModeP"]
    $AntiStopLoss_ModeP = [int]$inifile["AntiStopLoss_ModeP"]
    if (($Pending_Distance_ModeP -eq 0) -and ($StopLoss_ModeP -eq 0) -and ($TakeProfit_ModeP -eq 0) -and ($MinProfitToClose_ModeP -eq 0) -and ($TrailingStop_ModeP -eq 0) -and ($Martingail_ModeP -eq 0) -and ($AntiMartingail_ModeP -eq 0) -and ($AntiStopLoss_ModeP -eq 0)) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            VolPV_Type = "0"
        }
    }

    #ZigZag AND (MA_Filter 1 2 && 3) Distance
    $ZZ_Type = [int]$inifile["ZZ_Type"]
    $MA_Filter_1_Type = [int]$inifile["MA_Filter_1_Type"]
    $MA_Filter_2_Type = [int]$inifile["MA_Filter_2_Type"]
    $MA_Filter_3_Type = [int]$inifile["MA_Filter_3_Type"]
    if (($ZZ_Type -eq 0) -and ($MA_Filter_1_Type -eq 0) -and ($MA_Filter_2_Type -eq 0) -and ($MA_Filter_3_Type -eq 0)) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            VolMA_Type = "0"
        }
    }

    #If not Enabled, Don't use for open
    $DirChange_Type = [int]$inifile["DirChange_Type"]
    if ($DirChange_Type -eq 0) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            DirChange_OpenOn = "0"
        }
    }
    IndicatorIfNotValidOption -FilePath $FilePath -indy "DirChange" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "BigCandle" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "Oscillators" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "Oscillator2" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "Oscillator3" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "IdentifyTrend" -EnableTypeMode "Enable"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "TDI" -EnableTypeMode "Mode"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "MACD" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "MACD2" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "ADX" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "DTrend" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "PSar" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "MA_Filter_1" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "MA_Filter_2" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "MA_Filter_3" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "ZZ" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "VolFilter" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "FIBO" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "FIB2" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "CustomIndy1" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "CustomIndy2" -EnableTypeMode "Type"
    IndicatorIfNotValidOption -FilePath $FilePath -indy "CustomIndy3" -EnableTypeMode "Type"

    return $true
}

# Rename Setting File
function ButtonRename {
    Param(
        [string]$FilePath
    )

    $fileNewName = "_"

    #Read All Setting File parameters
    $inifile = Get-IniFile($FilePath)

    $VolPV_Type = [int]$inifile["VolPV_Type"]
    if ($VolPV_Type -eq 1) {
        $fileNewName = $fileNewName + "VolParamATR_"
    }
    elseif ($VolPV_Type -eq 2) {
        $fileNewName = $fileNewName + "VolParamStdDev_"
    }
    elseif ($VolPV_Type -eq 3) {
        $fileNewName = $fileNewName + "VolParamATR_CloseOpen_"
    }
    elseif ($VolPV_Type -eq 4) {
        $fileNewName = $fileNewName + "VolParamWATR_"
    }
    elseif ($VolPV_Type -eq 5) {
        $fileNewName = $fileNewName + "VolParamVolume_"
    }

    $DirChange = [int]$inifile["DirChange_Type"]
    if ($DirChange -ne 0) {
        $fileNewName = $fileNewName + "DirChange_"
    }

    $BigCandle = [int]$inifile["BigCandle_Type"]
    if ($BigCandle -ne 0) {
        $fileNewName = $fileNewName + "BigCandle_"
    }

    $Oscillators = [int]$inifile["Oscillators_Type"]
    if ($Oscillators -ne 0) {
        $Oscillators_Indicator = [int]$inifile["Oscillators_Indicator"]
        if ($Oscillators_Indicator -eq 0) {
            $fileNewName = $fileNewName + "CCI1_"
        }
        elseif ($Oscillators_Indicator -eq 1) {
            $fileNewName = $fileNewName + "WPR1_"
        }
        elseif ($Oscillators_Indicator -eq 2) {
            $fileNewName = $fileNewName + "RSI1_"
        }
        elseif ($Oscillators_Indicator -eq 3) {
            $fileNewName = $fileNewName + "StochasticK1_"
        }
        elseif ($Oscillators_Indicator -eq 5) {
            #Andrey change the number of index
            $fileNewName = $fileNewName + "StochasticD1_"
        }
        elseif ($Oscillators_Indicator -eq 4) {
            $fileNewName = $fileNewName + "Momentum1_"
        }
    }

    $Oscillator2 = [int]$inifile["Oscillator2_Type"]
    if ($Oscillator2 -ne 0) {
        $Oscillator2_Indicator = [int]$inifile["Oscillator2_Indicator"]
        if ($Oscillator2_Indicator -eq 0) {
            $fileNewName = $fileNewName + "CCI2_"
        }
        elseif ($Oscillator2_Indicator -eq 1) {
            $fileNewName = $fileNewName + "WPR2_"
        }
        elseif ($Oscillator2_Indicator -eq 2) {
            $fileNewName = $fileNewName + "RSI2_"
        }
        elseif ($Oscillator2_Indicator -eq 3) {
            $fileNewName = $fileNewName + "StochasticK2_"
        }
        elseif ($Oscillator2_Indicator -eq 5) {
            #Andrey change the number of index
            $fileNewName = $fileNewName + "StochasticD2_"
        }
        elseif ($Oscillator2_Indicator -eq 4) {
            $fileNewName = $fileNewName + "Momentum2_"
        }
    }

    $Oscillator3 = [int]$inifile["Oscillator3_Type"]
    if ($Oscillator3 -ne 0) {
        $Oscillator3_Indicator = [int]$inifile["Oscillator3_Indicator"]
        if ($Oscillator3_Indicator -eq 0) {
            $fileNewName = $fileNewName + "CCI3_"
        }
        elseif ($Oscillator3_Indicator -eq 1) {
            $fileNewName = $fileNewName + "WPR3_"
        }
        elseif ($Oscillator3_Indicator -eq 2) {
            $fileNewName = $fileNewName + "RSI3_"
        }
        elseif ($Oscillator3_Indicator -eq 3) {
            $fileNewName = $fileNewName + "StochasticK3_"
        }
        elseif ($Oscillator3_Indicator -eq 5) {
            #Andrey change the number of index
            $fileNewName = $fileNewName + "StochasticD3_"
        }
        elseif ($Oscillator3_Indicator -eq 4) {
            $fileNewName = $fileNewName + "Momentum3_"
        }
    }

    $IdentifyTrend = [string]$inifile["IdentifyTrend_Enable"]
    if ($IdentifyTrend -eq "true") {
        $fileNewName = $fileNewName + "IdentifyTrend_"
    }

    $TDI = [int]$inifile["TDI_Mode"]
    if ($TDI -ne 0) {
        $fileNewName = $fileNewName + "TDI_"
    }

    $MACD = [int]$inifile["MACD_Type"]
    if ($MACD -ne 0) {
        $fileNewName = $fileNewName + "MACD1_"
    }

    $MACD2 = [int]$inifile["MACD2_Type"]
    if ($MACD2 -ne 0) {
        $fileNewName = $fileNewName + "MACD2_"
    }

    $ADX = [int]$inifile["ADX_Type"]
    if ($ADX -ne 0) {
        $fileNewName = $fileNewName + "ADX_"
    }

    $DTrend = [int]$inifile["DTrend_Type"]
    if ($DTrend -ne 0) {
        $fileNewName = $fileNewName + "DTrend_"
    }

    $PSar_Type = [int]$inifile["PSar_Type"]
    if ($PSar_Type -eq 1) {
        #Parabolic SAR Direction
        $fileNewName = $fileNewName + "PSarDirection_"
    }
    elseif ($PSar_Type -eq 2) {
        #Parabolic SAR Signal
        $fileNewName = $fileNewName + "PSarSignal_"
    }

    $MA_Filter_1 = [int]$inifile["MA_Filter_1_Type"]
    if ($MA_Filter_1 -ne 0) {
        $MA_Filter_1_Method = [int]$inifile["MA_Filter_1_Method"]
        if ($MA_Filter_1_Method -eq 0) {
            #Simple Moving Average (SMA)
            $fileNewName = $fileNewName + "MA1_Simple_"
        }
        elseif ($MA_Filter_1_Method -eq 1) {
            #Exponential Moving Average (EMA)
            $fileNewName = $fileNewName + "MA1_Exponencial_"
        }
        elseif ($MA_Filter_1_Method -eq 2) {
            #Smoothed Moving Average (SMMA)
            $fileNewName = $fileNewName + "MA1_Smoothed_"
        }
        elseif ($MA_Filter_1_Method -eq 3) {
            #Linear Weighted Moving Average (LWMA)
            $fileNewName = $fileNewName + "MA1_Linear_weighted_"
        }
        elseif ($MA_Filter_1_Method -eq 4) {
            $fileNewName = $fileNewName + "MA1_JurikMA_"
        }
        elseif ($MA_Filter_1_Method -eq 5) {
            #https://www.metatrader5.com/es/terminal/help/indicators/trend_indicators/fama
            $fileNewName = $fileNewName + "MA1_FRAMA_"
        }
        elseif ($MA_Filter_1_Method -eq 6) {
            $fileNewName = $fileNewName + "MA1_TMA_"
        }
        elseif ($MA_Filter_1_Method -eq 7) {
            $fileNewName = $fileNewName + "MA1_TEMA_"
        }
        elseif ($MA_Filter_1_Method -eq 9) {
            #Andrey not use Index 8(v2.38) "reserved for MODE_TRIX"
            $fileNewName = $fileNewName + "MA1_HMA_"
        }
    }

    $MA_Filter_2 = [int]$inifile["MA_Filter_2_Type"]
    if ($MA_Filter_2 -ne 0) {
        $MA_Filter_2_Method = [int]$inifile["MA_Filter_2_Method"]
        if ($MA_Filter_2_Method -eq 0) {
            $fileNewName = $fileNewName + "MA2_Simple_"
        }
        elseif ($MA_Filter_2_Method -eq 1) {
            $fileNewName = $fileNewName + "MA2_Exponencial_"
        }
        elseif ($MA_Filter_2_Method -eq 2) {
            $fileNewName = $fileNewName + "MA2_Smoothed_"
        }
        elseif ($MA_Filter_2_Method -eq 3) {
            $fileNewName = $fileNewName + "MA2_Linear_weighted_"
        }
        elseif ($MA_Filter_2_Method -eq 4) {
            $fileNewName = $fileNewName + "MA2_JurikMA_"
        }
        elseif ($MA_Filter_2_Method -eq 5) {
            $fileNewName = $fileNewName + "MA2_FRAMA_"
        }
        elseif ($MA_Filter_2_Method -eq 6) {
            $fileNewName = $fileNewName + "MA2_TMA_"
        }
        elseif ($MA_Filter_2_Method -eq 7) {
            $fileNewName = $fileNewName + "MA2_TEMA_"
        }
        elseif ($MA_Filter_2_Method -eq 9) {
            #Andrey not use Index 8(v2.38) "reserved for MODE_TRIX"
            $fileNewName = $fileNewName + "MA2_HMA_"
        }
    }

    $MA_Filter_3 = [int]$inifile["MA_Filter_3_Type"]
    if ($MA_Filter_3 -ne 0) {
        $MA_Filter_3_Method = [int]$inifile["MA_Filter_3_Method"]
        if ($MA_Filter_3_Method -eq 0) {
            $fileNewName = $fileNewName + "MA3_Simple_"
        }
        elseif ($MA_Filter_3_Method -eq 1) {
            $fileNewName = $fileNewName + "MA3_Exponencial_"
        }
        elseif ($MA_Filter_3_Method -eq 2) {
            $fileNewName = $fileNewName + "MA3_Smoothed_"
        }
        elseif ($MA_Filter_3_Method -eq 3) {
            $fileNewName = $fileNewName + "MA3_Linear_weighted_"
        }
        elseif ($MA_Filter_3_Method -eq 4) {
            $fileNewName = $fileNewName + "MA3_JurikMA_"
        }
        elseif ($MA_Filter_3_Method -eq 5) {
            $fileNewName = $fileNewName + "MA3_FRAMA_"
        }
        elseif ($MA_Filter_3_Method -eq 6) {
            $fileNewName = $fileNewName + "MA3_TMA_"
        }
        elseif ($MA_Filter_3_Method -eq 7) {
            $fileNewName = $fileNewName + "MA3_TEMA_"
        }
        elseif ($MA_Filter_3_Method -eq 9) {
            #Andrey not use Index 8(v2.38) "reserved for MODE_TRIX"
            $fileNewName = $fileNewName + "MA3_HMA_"
        }
    }

    $ZZ = [int]$inifile["ZZ_Type"]
    if ($ZZ -ne 0) {
        $fileNewName = $fileNewName + "ZZ_"
    }

    $VolFilter = [int]$inifile["VolFilter_Type"]
    if ($VolFilter -eq 1) {
        $fileNewName = $fileNewName + "VolFilterATR_"
    }
    elseif ($VolFilter -eq 2) {
        $fileNewName = $fileNewName + "VolFilterStdDev_"
    }
    elseif ($VolFilter -eq 3) {
        $fileNewName = $fileNewName + "VolFilterATR_CloseOpen_"
    }
    elseif ($VolFilter -eq 4) {
        $fileNewName = $fileNewName + "VolFilterWATR_"
    }
    elseif ($VolFilter -eq 5) {
        $fileNewName = $fileNewName + "VolFilterVolume_"
    }

    $FIBO = [int]$inifile["FIBO_Type"]
    if ($FIBO -ne 0) {
        $fileNewName = $fileNewName + "FIBO1_"
    }

    $FIB2 = [int]$inifile["FIB2_Type"]
    if ($FIB2 -ne 0) {
        $fileNewName = $fileNewName + "FIBO2_"
    }

    $CustomIndy1 = [int]$inifile["CustomIndy1_Type"]
    if ($CustomIndy1 -ne 0) {
        $CustomIndy1_DrawShortName = [string]$inifile["CustomIndy1_DrawShortName"]
        $fileNewName = $fileNewName + "CustomIndy1_" + $CustomIndy1_DrawShortName + "_"
    }

    $CustomIndy2 = [int]$inifile["CustomIndy2_Type"]
    if ($CustomIndy2 -ne 0) {
        $CustomIndy2_DrawShortName = [string]$inifile["CustomIndy2_DrawShortName"]
        $fileNewName = $fileNewName + "CustomIndy2_" + $CustomIndy2_DrawShortName + "_"
    }

    $CustomIndy3 = [int]$inifile["CustomIndy3_Type"]
    if ($CustomIndy3 -ne 0) {
        $CustomIndy3_DrawShortName = [string]$inifile["CustomIndy3_DrawShortName"]
        $fileNewName = $fileNewName + "CustomIndy3_" + $CustomIndy3_DrawShortName + "_"
    }

    $News = [int]$inifile["News_Mode"]
    if ($News -eq 1) {
        $fileNewName = $fileNewName + "News_"
    }
    if ($News -eq 2) {
        $fileNewName = $fileNewName + "No_Traded_On_News_"
    }

    $fileNewName = $fileNewName.Substring(0, $fileNewName.Length - 1)
    $PathDest = (Get-Item $FilePath).BaseName + $fileNewName + ".set"
    $CurrentDir = Split-Path -Path "$FilePath"
    Copy-Item "$FilePath" -Destination "$CurrentDir\$PathDest"

    if (!(Test-Path -Path "$CurrentDir\$Destino")) {
        return [bool]$false, 'Cant copy file. Reduce the PATH: $CurrentDir . Move the file, for example to C:\temp'
    }

    return [bool]$true, ""
}

#Cross EMA. 20Fast 50Slow
function Button2EMACross_1 {
    Param(
        [string]$FilePath
    )

    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
        MACD_Properties      = "===== 2 EMA Cross #1 ====="
        MACD_Type            = "1"
        MACD_TF              = "5"
        MACD_PeriodFast      = "20"
        MACD_FastMA_Method   = "1"
        MACD_PeriodSlow      = "50"
        MACD_SlowMA_Method   = "1"
        MACD_PeriodSignal    = "9"
        MACD_SignalMA_Method = "0"
        MACD_Price           = "1"
        MACD_JMA_Phase       = "0"
        MACD_Reverse         = "false"
        MACD_UseClosedBars   = "true"
        MACD_OpenOn          = "1"
        MACD_MartinOn        = "0"
        MACD_HedgeOn         = "0"
        MACD_CloseOn         = "1"
        MACD_PartialCloseOn  = "0"
    }

    return $true
}

#Cross EMA. 20Fast 50Slow
function Button2EMACross_2 {
    Param(
        [string]$FilePath
    )

    Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
        MACD2_Properties      = "===== 2 EMA Cross #2 ====="
        MACD2_Type            = "1"
        MACD2_TF              = "5"
        MACD2_PeriodFast      = "20"
        MACD2_FastMA_Method   = "1"
        MACD2_PeriodSlow      = "50"
        MACD2_SlowMA_Method   = "1"
        MACD2_PeriodSignal    = "9"
        MACD2_SignalMA_Method = "0"
        MACD2_Price           = "1"
        MACD2_JMA_Phase       = "0"
        MACD2_Reverse         = "false"
        MACD2_UseClosedBars   = "true"
        MACD2_OpenOn          = "1"
        MACD2_MartinOn        = "0"
        MACD2_HedgeOn         = "0"
        MACD2_CloseOn         = "1"
        MACD2_PartialCloseOn  = "0"
    }
    return $true
}

#Bollinger Bands Explained
#https://www.metatrader5.com/en/terminal/help/indicators/trend_indicators/bb
#https://academy.binance.com/en/articles/bollinger-bands-explained
#
#https://admiralmarkets.com/es/education/articles/forex-strategy/bandas-de-bollinger
#Bandas de Bollinger y RSI
#En esta estrategia de trading vamos a utilizar los indicadores Bandas de Bollinger y RSI. El indicador RSI actúa como filtro para tratar de mejorar la efectividad de las señales generadas con las bandas de Bollinger. Esto reduce el número de operaciones, pero debería aumentar la proporción de posiciones ganadoras.
#
#https://www.investopedia.com/terms/b/bollingerbands.asp
#The following traits are particular to the Bollinger Band:
#abrupt changes in prices tend to happen after the band has contracted due to decrease of volatility;
#if prices break through one of the bands, a continuation of the current trend is to be expected;
#if the pikes and hollows outside the band are followed by pikes and hollows inside the band, a reverse of trend may occur;
#the price movement that has started from one of the band’s lines usually reaches the opposite one.
#ML = SUM (CLOSE, N) / N = SMA (CLOSE, N)
#TL = ML + (D * StdDev)
#BL = ML - (D * StdDev)
function ButtonBollingerBands {
    Param(
        [string]$FilePath,
        [string]$Number
    )

    IndicatorsWithMA -FilePath $FilePath -Name "BollingerBands" -Number $Number -Filter_Type "1" -Filter_Period "20" -Filter_Method "0" -Filter_Price "1" -Filter_DistType "1" -Filter_DistCoef "2" -Filter_OpenOn "1" -Filter_CloseOn "1" -VolMA_Type "2" -VolMA_Period "20"

    return $true
}

#https://www.mql5.com/en/market/product/79942?source=Site+Search#description
#BB Squeeze MT5
#KT BB Squeeze measures the contraction and expansion of market volatility with a momentum oscillator, which can be used to decide a trading direction. It measures the squeeze in volatility by deducing the relationship between the Bollinger Bands and Keltner channels.
#Momentum(20)
#Bollinger Bands Period(20)
#Bollinger Bands Deviation(2.0)
#Keltner Channels Period (20)
#Keltner Channels Multiplication (1.5)
#The gray dots represent the period of low volatility when Bollinger Bands are inside the Keltner channels.
#The white dots represent the period of high volatility when Bollinger Bands are outside the Keltner channels.


#Keltner Channel - indicator for MetaTrader 5
#https://www.mql5.com/en/code/399
#
#https://www.investopedia.com/terms/k/keltnerchannel.asp
#Keltner Channels are volatility-based bands that are placed on either side of an asset's price and can aid in determining the direction of a trend.
#The Keltner channel uses the average-true range (ATR) or volatility, with breaks above or below the top and bottom barriers signaling a continuation.
#Keltner Channel Calculation
#Keltner Channel Middle Line=EMA
#Keltner Channel Upper Band=EMA+2∗ATR
#Keltner Channel Lower Band=EMA−2∗ATR
#The exponential moving average (EMA) of a Keltner Channel is typically 20 periods, although this can be adjusted if desired.
#The upper and lower bands are typically set two times the average true range (ATR) above and below the EMA, although the multiplier can also be adjusted based on personal preference.
#Price reaching the upper Keltner Channel band is bullish, while reaching the lower band is bearish.
#The angle of the Keltner Channel also aids in identifying the trend direction. The price may also oscillate between the upper and lower Keltner Channel bands, which can be interpreted as resistance and support levels.
#Good Result
#TF=1M
#Smoothed(20) + 2*ATR(20)
#EMA(20) + 2*ATR(10)
function ButtonKeltnerChannel {
    Param(
        [string]$FilePath,
        [string]$Number
    )

    IndicatorsWithMA -FilePath $FilePath -Name "Keltner Channel" -Number $Number -Filter_Type "1" -Filter_Period "20" -Filter_Method "1" -Filter_Price "1" -Filter_DistType "1" -Filter_DistCoef "2" -Filter_OpenOn "1" -Filter_CloseOn "1" -VolMA_Type "1" -VolMA_Period "20"

    return $true
}

#https://www.investopedia.com/terms/s/starc.asp
#Stoller Average Range Channel
#STARC Band +=SMA+(Multiplier×ATR)
#STARC Band −=SMA−(Multiplier×ATR)
function ButtonSTARC {
    Param(
        [string]$FilePath,
        [string]$Number
    )

    IndicatorsWithMA -FilePath $FilePath -Name "Stoller Average Range Channel" -Number $Number -Filter_Type "1" -Filter_Period "20" -Filter_Method "0" -Filter_Price "1" -Filter_DistType "1" -Filter_DistCoef "2" -Filter_OpenOn "1" -Filter_CloseOn "1" -VolMA_Type "1" -VolMA_Period "20"

    return $true
}

#CustomIndy 1, 2, 3
function ButtonCustomIndy_X {
    Param(
        [string]$FilePath,
        [string]$Number,
        [string]$Name
    )

    #Buffer Reader For MT5
    #The Buffer Reader will help you to check and export the custom indicators buffers data for your current chart and timeframe.
    #https://www.mql5.com/en/market/product/52964?source=Unknown

    $CustomIndy_Properties = "CustomIndy" + $Number + "_Properties"
    $CustomIndy_Label = "CustomIndy" + $Number + "_Label"
    $CustomIndy_Type = "CustomIndy" + $Number + "_Type"
    $CustomIndy_TF = "CustomIndy" + $Number + "_TF"
    $CustomIndy_PathAndName = "CustomIndy" + $Number + "_PathAndName"
    $CustomIndy_ParametersStr = "CustomIndy" + $Number + "_ParametersStr"
    $CustomIndy_BufferB = "CustomIndy" + $Number + "_BufferB"
    $CustomIndy_BufferS = "CustomIndy" + $Number + "_BufferS"
    $CustomIndy_ColorBufferB = "CustomIndy" + $Number + "_ColorBufferB"
    $CustomIndy_ColorBufferS = "CustomIndy" + $Number + "_ColorBufferS"
    $CustomIndy_ColorIndexB = "CustomIndy" + $Number + "_ColorIndexB"
    $CustomIndy_ColorIndexS = "CustomIndy" + $Number + "_ColorIndexS"
    $CustomIndy_LevelMaxB = "CustomIndy" + $Number + "_LevelMaxB"
    $CustomIndy_LevelMinB = "CustomIndy" + $Number + "_LevelMinB"
    $CustomIndy_LevelMaxS = "CustomIndy" + $Number + "_LevelMaxS"
    $CustomIndy_LevelMinS = "CustomIndy" + $Number + "_LevelMinS"
    $CustomIndy_Reverse = "CustomIndy" + $Number + "_Reverse"
    $CustomIndy_UseClosedBars = "CustomIndy" + $Number + "_UseClosedBars"
    $CustomIndy_DrawShortName = "CustomIndy" + $Number + "_DrawShortName"
    $CustomIndy_DrawInSubwindow = "CustomIndy" + $Number + "_DrawInSubwindow"
    $CustomIndy_AllowNegativeAndZero = "CustomIndy" + $Number + "_AllowNegativeAndZero"
    $CustomIndy_OpenOn = "CustomIndy" + $Number + "_OpenOn"
    $CustomIndy_MartinOn = "CustomIndy" + $Number + "_MartinOn"
    $CustomIndy_HedgeOn = "CustomIndy" + $Number + "_HedgeOn"
    $CustomIndy_CloseOn = "CustomIndy" + $Number + "_CloseOn"
    $CustomIndy_PartialCloseOn = "CustomIndy" + $Number + "_PartialCloseOn"

    #SuperTrend
    #https://www.mql5.com/en/code/576
    #SetIndexBuffer(0,Filled_a,INDICATOR_DATA);
    #SetIndexBuffer(1,Filled_b,INDICATOR_DATA);
    #SetIndexBuffer(2,SuperTrend,INDICATOR_DATA);
    #SetIndexBuffer(3,ColorBuffer,INDICATOR_COLOR_INDEX);
    #SetIndexBuffer(4,Atr,INDICATOR_CALCULATIONS);
    #SetIndexBuffer(5,Up,INDICATOR_CALCULATIONS);
    #SetIndexBuffer(6,Down,INDICATOR_CALCULATIONS);
    #SetIndexBuffer(7,Middle,INDICATOR_CALCULATIONS);
    #SetIndexBuffer(8,trend,INDICATOR_CALCULATIONS);
    if ($Name -eq "SuperTrend" ) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            $CustomIndy_Label                = "SuperTrend"
            $CustomIndy_Type                 = "3"
            $CustomIndy_TF                   = "5"
            $CustomIndy_PathAndName          = "supertrend"
            $CustomIndy_ParametersStr        = "10,3,0"
            $CustomIndy_BufferB              = "2"
            $CustomIndy_BufferS              = "2"
            $CustomIndy_ColorBufferB         = "3"
            $CustomIndy_ColorBufferS         = "3"
            $CustomIndy_ColorIndexB          = "0"
            $CustomIndy_ColorIndexS          = "1"
            $CustomIndy_LevelMaxB            = "-999"
            $CustomIndy_LevelMinB            = "-999"
            $CustomIndy_LevelMaxS            = "-999"
            $CustomIndy_LevelMinS            = "-999"
            $CustomIndy_Reverse              = "false"
            $CustomIndy_UseClosedBars        = "true"
            $CustomIndy_DrawShortName        = "Supertrend"
            $CustomIndy_DrawInSubwindow      = "false"
            $CustomIndy_AllowNegativeAndZero = "true"
            $CustomIndy_OpenOn               = "1"
            $CustomIndy_MartinOn             = "0"
            $CustomIndy_HedgeOn              = "0"
            $CustomIndy_CloseOn              = "2"
            $CustomIndy_PartialCloseOn       = "0"
        }
    }

    #Bollinger bands breakout
    #https://www.mql5.com/en/code/24612
    #SetIndexBuffer(0,fupu    ,INDICATOR_DATA);
    #SetIndexBuffer(1,fupd    ,INDICATOR_DATA);
    #SetIndexBuffer(2,fdnu    ,INDICATOR_DATA);
    #SetIndexBuffer(3,fdnd    ,INDICATOR_DATA);
    #SetIndexBuffer(4,bufferUp,INDICATOR_DATA);
    #SetIndexBuffer(5,bufferDn,INDICATOR_DATA);
    #SetIndexBuffer(6,bufferMe,INDICATOR_DATA);
    #SetIndexBuffer(7,breakup ,INDICATOR_DATA); PlotIndexSetInteger(5,PLOT_ARROW,217); PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,-10);
    #SetIndexBuffer(8,breakdn ,INDICATOR_DATA);
    if ($Name -eq "Bollinger bands breakout" ) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            CustomIndy_Label           = "Bollinger bands breakout"
            CustomIndy_Type            = "3"
            CustomIndy_TF              = "5"
            CustomIndy_PathAndName     = "Bollinger bands breakout"
            $CustomIndy_ParametersStr   = "20,1,2.0,20.0,1"
            $CustomIndy_BufferB         = "7"
            $CustomIndy_BufferS         = "8"
            $CustomIndy_ColorBufferB    = "-1"
            $CustomIndy_ColorBufferS    = "-1"
            $CustomIndy_ColorIndexB     = "-1"
            $CustomIndy_ColorIndexS     = "-1"
            $CustomIndy_LevelMaxB       = "-999"
            $CustomIndy_LevelMinB       = "-999"
            $CustomIndy_LevelMaxS       = "-999"
            $CustomIndy_LevelMinS       = "-999"
            $CustomIndy_Reverse         = "false"
            $CustomIndy_UseClosedBars   = "true"
            $CustomIndy_DrawShortName   = "Bollinger bands breakout"
            $CustomIndy_DrawInSubwindow = "false"
            $CustomIndy_OpenOn          = "1"
            $CustomIndy_MartinOn        = "0"
            $CustomIndy_HedgeOn         = "0"
            $CustomIndy_CloseOn         = "2"
            $CustomIndy_PartialCloseOn  = "0"
        }
    }

    #TrendLine PRO MT5
    #https://www.mql5.com/en/market/product/42399
    if ($Name -eq "TrendLine PRO MT5" ) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            CustomIndy_Label                 = "TrendLine"
            CustomIndy_Type                  = "3"
            CustomIndy_TF                    = "5"
            CustomIndy_PathAndName           = "Market\TrendLine PRO MT5"
            CustomIndy_ParametersStr         = ""
            CustomIndy_BufferB               = "7"
            $CustomIndy_BufferS              = "8"
            $CustomIndy_ColorBufferB         = "7"
            $CustomIndy_ColorBufferS         = "8"
            $CustomIndy_ColorIndexB          = "0"
            $CustomIndy_ColorIndexS          = "0"
            $CustomIndy_LevelMaxB            = "-999"
            $CustomIndy_LevelMinB            = "-999"
            $CustomIndy_LevelMaxS            = "-999"
            $CustomIndy_LevelMinS            = "-999"
            $CustomIndy_Reverse              = "false"
            $CustomIndy_UseClosedBars        = "true"
            $CustomIndy_DrawShortName        = "TrendLine"
            $CustomIndy_DrawInSubwindow      = "false"
            $CustomIndy_AllowNegativeAndZero = "true"
            $CustomIndy_OpenOn               = "1"
            $CustomIndy_MartinOn             = "0"
            $CustomIndy_HedgeOn              = "0"
            $CustomIndy_CloseOn              = "2"
            $CustomIndy_PartialCloseOn       = "0"
        }
    }

    #HMA Color with Alerts MT5
    #https://www.mql5.com/en/market/product/27341
    if ($Name -eq "HMA Color with Alerts MT5" ) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            $CustomIndy_Label                = "HMA Color"
            $CustomIndy_Type                 = "3"
            $CustomIndy_TF                   = "5"
            $CustomIndy_PathAndName          = "Market\HMA Color with Alerts MT5"
            $CustomIndy_ParametersStr        = ""
            $CustomIndy_BufferB              = "0"
            $CustomIndy_BufferS              = "0"
            $CustomIndy_ColorBufferB         = "1"
            $CustomIndy_ColorBufferS         = "1"
            $CustomIndy_ColorIndexB          = "0"
            $CustomIndy_ColorIndexS          = "1"
            $CustomIndy_LevelMaxB            = "-999"
            $CustomIndy_LevelMinB            = "-999"
            $CustomIndy_LevelMaxS            = "-999"
            $CustomIndy_LevelMinS            = "-999"
            $CustomIndy_Reverse              = "false"
            $CustomIndy_UseClosedBars        = "true"
            $CustomIndy_DrawShortName        = "HMA"
            $CustomIndy_DrawInSubwindow      = "false"
            $CustomIndy_AllowNegativeAndZero = "true"
            $CustomIndy_OpenOn               = "1"
            $CustomIndy_MartinOn             = "0"
            $CustomIndy_HedgeOn              = "0"
            $CustomIndy_CloseOn              = "2"
            $CustomIndy_PartialCloseOn       = "0"
        }
    }

    #HMA Color with Alerts MT5
    #https://www.mql5.com/en/market/product/27341
    if ($Name -eq "HMA Color with Alerts MT5" ) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            $CustomIndy_Label                = "HMA Color"
            $CustomIndy_Type                 = "3"
            $CustomIndy_TF                   = "5"
            $CustomIndy_PathAndName          = "Market\HMA Color with Alerts MT5"
            $CustomIndy_ParametersStr        = ""
            $CustomIndy_BufferB              = "0"
            $CustomIndy_BufferS              = "0"
            $CustomIndy_ColorBufferB         = "1"
            $CustomIndy_ColorBufferS         = "1"
            $CustomIndy_ColorIndexB          = "0"
            $CustomIndy_ColorIndexS          = "1"
            $CustomIndy_LevelMaxB            = "-999"
            $CustomIndy_LevelMinB            = "-999"
            $CustomIndy_LevelMaxS            = "-999"
            $CustomIndy_LevelMinS            = "-999"
            $CustomIndy_Reverse              = "false"
            $CustomIndy_UseClosedBars        = "true"
            $CustomIndy_DrawShortName        = "HMA"
            $CustomIndy_DrawInSubwindow      = "false"
            $CustomIndy_AllowNegativeAndZero = "true"
            $CustomIndy_OpenOn               = "1"
            $CustomIndy_MartinOn             = "0"
            $CustomIndy_HedgeOn              = "0"
            $CustomIndy_CloseOn              = "2"
            $CustomIndy_PartialCloseOn       = "0"
        }
    }

    #Half Trend New Alert - indicator for MetaTrader 5
    #https://www.mql5.com/en/code/39446
    #//--- indicator buffers mapping
    #SetIndexBuffer(0,LineBuffer,INDICATOR_DATA);
    #SetIndexBuffer(1,LineColors,INDICATOR_COLOR_INDEX);
    #SetIndexBuffer(2,UpBuffer,INDICATOR_DATA);
    #SetIndexBuffer(3,DownBuffer,INDICATOR_DATA);
    #SetIndexBuffer(4,HighestBuffer,INDICATOR_DATA);
    #SetIndexBuffer(5,LowestBuffer,INDICATOR_DATA);
    #SetIndexBuffer(6,MA_PRICE_HIGH_Buffer,INDICATOR_CALCULATIONS);
    #SetIndexBuffer(7,MA_PRICE_LOW_Buffer,INDICATOR_CALCULATIONS);
    if ($Name -eq "Half Trend New Alert" ) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            $CustomIndy_Properties           = "===== Half Trend #" + $Number + " ====="
            $CustomIndy_Label                = "Half Trend"
            $CustomIndy_Type                 = "3"
            $CustomIndy_TF                   = "5"
            $CustomIndy_PathAndName          = "Half Trend New Alert"
            $CustomIndy_ParametersStr        = "5,'alert.wav',3,3,0,0,0,0"
            $CustomIndy_BufferB              = "0"
            $CustomIndy_BufferS              = "0"
            $CustomIndy_ColorBufferB         = "1"
            $CustomIndy_ColorBufferS         = "1"
            $CustomIndy_ColorIndexB          = "0"
            $CustomIndy_ColorIndexS          = "1"
            $CustomIndy_LevelMaxB            = "-999"
            $CustomIndy_LevelMinB            = "-999"
            $CustomIndy_LevelMaxS            = "-999"
            $CustomIndy_LevelMinS            = "-999"
            $CustomIndy_Reverse              = "false"
            $CustomIndy_UseClosedBars        = "true"
            $CustomIndy_DrawShortName        = "Half Trend"
            $CustomIndy_DrawInSubwindow      = "false"
            $CustomIndy_AllowNegativeAndZero = "true"
            $CustomIndy_OpenOn               = "1"
            $CustomIndy_MartinOn             = "0"
            $CustomIndy_HedgeOn              = "0"
            $CustomIndy_CloseOn              = "2"
            $CustomIndy_PartialCloseOn       = "0"
        }
    }



    #Disable Custom Indicator
    if ($Name -eq "DisableCustomIndy" ) {
        Set-OrAddIniValue -FilePath $FilePath  -keyValueList @{
            $CustomIndy_Properties           = "===== Custom Indy #" + $Number + " ====="
            $CustomIndy_Label                = "Custom Indicator"
            $CustomIndy_Type                 = "0"
            $CustomIndy_TF                   = "0"
            $CustomIndy_PathAndName          = "MyIndicators\MyBestIndy"
            $CustomIndy_ParametersStr        = ""
            $CustomIndy_BufferB              = "-1"
            $CustomIndy_BufferS              = "-1"
            $CustomIndy_ColorBufferB         = "-1"
            $CustomIndy_ColorBufferS         = "-1"
            $CustomIndy_ColorIndexB          = "-1"
            $CustomIndy_ColorIndexS          = "-1"
            $CustomIndy_LevelMaxB            = "-999"
            $CustomIndy_LevelMinB            = "-999"
            $CustomIndy_LevelMaxS            = "-999"
            $CustomIndy_LevelMinS            = "-999"
            $CustomIndy_Reverse              = "false"
            $CustomIndy_UseClosedBars        = "true"
            $CustomIndy_DrawShortName        = "MyBestIndy"
            $CustomIndy_DrawInSubwindow      = "false"
            $CustomIndy_AllowNegativeAndZero = "true"
            $CustomIndy_OpenOn               = "0"
            $CustomIndy_MartinOn             = "0"
            $CustomIndy_HedgeOn              = "0"
            $CustomIndy_CloseOn              = "0"
            $CustomIndy_PartialCloseOn       = "0"
        }
    }
    return $true
}

#Detect GRID
function ButtonDetectGRID {
    Param(
        [string]$FilePath
    )
    if (!(DetectGRID -FilePath $FilePath -indy "DirChange")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "BigCandle")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "Oscillators")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "Oscillator2")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "Oscillator3")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "IdentifyTrend")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "TDI")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "MACD")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "MACD2")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "ADX")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "DTrend")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "PSar")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "MA_Filter_1")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "MA_Filter_2")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "MA_Filter_3")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "ZZ")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "VolFilter")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "FIBO")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "FIB2")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "CustomIndy1")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "CustomIndy2")) {
        return $false
    }
    if (!(DetectGRID -FilePath $FilePath -indy "CustomIndy3")) {
        return $false
    }
    return $true
}

#Convert a GRID
function ButtonConvertToGRID {
    Param(
        [string]$FilePath
    )
    ConvertToGRID -FilePath $FilePath -indy "DirChange"
    ConvertToGRID -FilePath $FilePath -indy "BigCandle"
    ConvertToGRID -FilePath $FilePath -indy "Oscillators"
    ConvertToGRID -FilePath $FilePath -indy "Oscillator2"
    ConvertToGRID -FilePath $FilePath -indy "Oscillator3"
    ConvertToGRID -FilePath $FilePath -indy "IdentifyTrend"
    ConvertToGRID -FilePath $FilePath -indy "TDI"
    ConvertToGRID -FilePath $FilePath -indy "MACD"
    ConvertToGRID -FilePath $FilePath -indy "MACD2"
    ConvertToGRID -FilePath $FilePath -indy "ADX"
    ConvertToGRID -FilePath $FilePath -indy "DTrend"
    ConvertToGRID -FilePath $FilePath -indy "PSar"
    ConvertToGRID -FilePath $FilePath -indy "MA_Filter_1"
    ConvertToGRID -FilePath $FilePath -indy "MA_Filter_2"
    ConvertToGRID -FilePath $FilePath -indy "MA_Filter_3"
    ConvertToGRID -FilePath $FilePath -indy "ZZ"
    ConvertToGRID -FilePath $FilePath -indy "VolFilter"
    ConvertToGRID -FilePath $FilePath -indy "FIBO"
    ConvertToGRID -FilePath $FilePath -indy "FIB2"
    ConvertToGRID -FilePath $FilePath -indy "CustomIndy1"
    ConvertToGRID -FilePath $FilePath -indy "CustomIndy2"
    ConvertToGRID -FilePath $FilePath -indy "CustomIndy3"
}

#######################GUI################################################################
### API Windows Forms ###
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

### Create form ###
$form = New-Object System.Windows.Forms.Form
$form.Text = "My Defaults, Rename Setting File and Create Indicators - CommunityPower EA"
$form.Size = '750,500'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True

### Define controls ###
# Combobox
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = '280,10'
$comboBox.Size = '280,50'
$comboBox.DropDownStyle = 'DropDownList'
$comboBox.AutoCompleteSource = 'ListItems'
$comboBox.AutoCompleteMode = 'Append'
$comboBox.Items.AddRange( @("", "DisableTime", "ASIA(Tokyo/Hong Kong/Singapore)", "EUROPA(Frankfurt/London)" , "AMERICA(New York/Chicago)", "PACIFICO(Wellington/Sidney)", "DateTime-EUR/USD", "DateTime-XAU/USD", "MyDefault-EUR/USD", "No Traded On Critical News"))

# Combobox #1
$comboBox1 = New-Object System.Windows.Forms.ComboBox
$comboBox1.Location = '370,100'
$comboBox1.Size = '190,50'
$comboBox1.DropDownStyle = 'DropDownList'
$comboBox1.AutoCompleteSource = 'ListItems'
$comboBox1.AutoCompleteMode = 'Append'
$comboBox1.Items.AddRange( @("", "DisableCustomIndy", "SuperTrend", "TrendLine PRO MT5", "HMA Color with Alerts MT5", "Bollinger bands breakout", "Half Trend New Alert"))

# Combobox #2
$comboBox2 = New-Object System.Windows.Forms.ComboBox
$comboBox2.Location = '370,120'
$comboBox2.Size = '190,50'
$comboBox2.DropDownStyle = 'DropDownList'
$comboBox2.AutoCompleteSource = 'ListItems'
$comboBox2.AutoCompleteMode = 'Append'
$comboBox2.Items.AddRange( @("", "DisableCustomIndy", "SuperTrend", "TrendLine PRO MT5", "HMA Color with Alerts MT5", "Bollinger bands breakout", "Half Trend New Alert"))

# Combobox #3
$comboBox3 = New-Object System.Windows.Forms.ComboBox
$comboBox3.Location = '370,140'
$comboBox3.Size = '190,50'
$comboBox3.DropDownStyle = 'DropDownList'
$comboBox3.AutoCompleteSource = 'ListItems'
$comboBox3.AutoCompleteMode = 'Append'
$comboBox3.Items.AddRange( @("", "DisableCustomIndy", "SuperTrend", "TrendLine PRO MT5", "HMA Color with Alerts MT5", "Bollinger bands breakout", "Half Trend New Alert"))



#https://forex-station.com/viewtopic.php?f=579495&t=8413842
#STR is a combination of   RSI:9  +  STOCH:5/3/3  +  CCI:13   STR (Strength Trend Reversal)

# Button
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,10'
$button.Size = '200,20'
$button.Text = "My Defaults"

# Button
$button2 = New-Object System.Windows.Forms.Button
$button2.Location = '5,40'
$button2.Size = '200,20'
$button2.Text = "Rename Setting File"

# Button
$button3 = New-Object System.Windows.Forms.Button
$button3.Location = '5,60'
$button3.Size = '200,20'
$button3.Text = "Clear"

# Button
$button4 = New-Object System.Windows.Forms.Button
$button4.Location = '5,100'
$button4.Size = '250,20'
$button4.Text = "EMA Cross #1 / Fast:20 - Slow:50 (MACD #1)"

# Button
$button5 = New-Object System.Windows.Forms.Button
$button5.Location = '5,120'
$button5.Size = '250,20'
$button5.Text = "EMA Cross #2 / Fast:20 - Slow:50 (MACD #2)"

# Button
$button6 = New-Object System.Windows.Forms.Button
$button6.Location = '5,160'
$button6.Size = '250,20'
$button6.Text = "Bollinger Bands #1 (MA #1 && Volatility)"

# Button
$button7 = New-Object System.Windows.Forms.Button
$button7.Location = '5,180'
$button7.Size = '250,20'
$button7.Text = "Bollinger Bands #2 (MA #2 && Volatility)"

# Button
$button8 = New-Object System.Windows.Forms.Button
$button8.Location = '5,200'
$button8.Size = '250,20'
$button8.Text = "Bollinger Bands #3 (MA #3 && Volatility)"

# Button
#https://www.investopedia.com/terms/k/keltnerchannel.asp
$button9 = New-Object System.Windows.Forms.Button
$button9.Location = '5,240'
$button9.Size = '250,20'
$button9.Text = "Keltner Channel #1 (MA #1 && Volatility)"

# Button
#https://www.investopedia.com/terms/k/keltnerchannel.asp
$button10 = New-Object System.Windows.Forms.Button
$button10.Location = '5,260'
$button10.Size = '250,20'
$button10.Text = "Keltner Channel #2 (MA #2 && Volatility)"

# Button
#https://www.investopedia.com/terms/k/keltnerchannel.asp
$button11 = New-Object System.Windows.Forms.Button
$button11.Location = '5,280'
$button11.Size = '250,20'
$button11.Text = "Keltner Channel #3 (MA #3 && Volatility)"

# Button
# https://www.investopedia.com/terms/s/starc.asp
$button12 = New-Object System.Windows.Forms.Button
$button12.Location = '5,320'
$button12.Size = '300,20'
$button12.Text = "Stoller Average Range Channel #1 (MA #1 && Volatility)"

# Button
# https://www.investopedia.com/terms/s/starc.asp
$button13 = New-Object System.Windows.Forms.Button
$button13.Location = '5,340'
$button13.Size = '300,20'
$button13.Text = "Stoller Average Range Channel #2 (MA #2 && Volatility)"

# Button
# https://www.investopedia.com/terms/s/starc.asp
$button14 = New-Object System.Windows.Forms.Button
$button14.Location = '5,360'
$button14.Size = '300,20'
$button14.Text = "Stoller Average Range Channel #3 (MA #3 && Volatility)"

# Button
$button15 = New-Object System.Windows.Forms.Button
$button15.Location = '580,100'
$button15.Size = '120,20'
$button15.Text = "Apply CustomIndy #1"

# Button
$button16 = New-Object System.Windows.Forms.Button
$button16.Location = '580,120'
$button16.Size = '120,20'
$button16.Text = "Apply CustomIndy #2"

# Button
$button163 = New-Object System.Windows.Forms.Button
$button163.Location = '580,140'
$button163.Size = '120,20'
$button163.Text = "Apply CustomIndy #3"

# Button
# GRID
$button17 = New-Object System.Windows.Forms.Button
$button17.Location = '280,160'
$button17.Size = '120,20'
$button17.Text = "Detect GRID Strategy"

# Button
# GRID
$button18 = New-Object System.Windows.Forms.Button
$button18.Location = '280,180'
$button18.Size = '120,20'
$button18.Text = "Convert to GRID Strategy"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Location = '220,12'
$label.AutoSize = $True
$label.Text = "Date Time:"

# Label
$label1 = New-Object System.Windows.Forms.Label
$label1.Location = '280,100'
$label1.AutoSize = $True
$label1.Text = "CustomIndy #1:"

# Label
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = '280,120'
$label2.AutoSize = $True
$label2.Text = "CustomIndy #2:"

# Label
$label23 = New-Object System.Windows.Forms.Label
$label23.Location = '280,140'
$label23.AutoSize = $True
$label23.Text = "CustomIndy #3:"


# Label
$label3 = New-Object System.Windows.Forms.Label
$label3.Location = '5,380'
$label3.AutoSize = $True
$label3.Text = "Drag and Drop files settings here:"

# Listbox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = '5,400'
$listBox.Size = '550,40'
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True

# StatusBar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"

## Add controls to form ###
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($button2)
$form.Controls.Add($button3)
$form.Controls.Add($button4)
$form.Controls.Add($button5)
$form.Controls.Add($button6)
$form.Controls.Add($button7)
$form.Controls.Add($button8)
$form.Controls.Add($button9)
$form.Controls.Add($button10)
$form.Controls.Add($button11)
$form.Controls.Add($button12)
$form.Controls.Add($button13)
$form.Controls.Add($button14)
$form.Controls.Add($button15)
$form.Controls.Add($button16)
$form.Controls.Add($button163)
$form.Controls.Add($buttonX)
$form.Controls.Add($button17)
$form.Controls.Add($button18)
$form.Controls.Add($label)
$form.Controls.Add($label1)
$form.Controls.Add($label2)
$form.Controls.Add($label23)
$form.Controls.Add($label3)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.Controls.Add($comboBox)
$form.Controls.Add($comboBox1)
$form.Controls.Add($comboBox2)
$form.Controls.Add($comboBox3)
$form.ResumeLayout()

### Write event handlers ###
#Defaults
$button_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            $status, $error = MyDefault -filePath $item
            if ($status) {
                [System.Windows.Forms.MessageBox]::Show('Successful - ' + $button.Text, 'Defaults Values', 0, 64)
                $statusBar.Text = "Successful Setting MyDefaults"
            }
            else {
                [System.Windows.Forms.MessageBox]::Show('ERROR. ' + $error , 'Defaults Values', 0, 16)
                $statusBar.Text = "ERROR." + $error
            }
        }
    }
}

#Rename
$button2_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonRename -filePath $item) {
                [System.Windows.Forms.MessageBox]::Show('Successful Renamed', 'Rename', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) files renamed")
            }
        }
    }
}

# Clear ListBox
$button3_Click = {
    $listBox.Items.Clear()
}

#MA cross
$button4_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (Button2EMACross_1 -filePath $item) {
                [System.Windows.Forms.MessageBox]::Show('MA cross signal #1 Applied', 'MA cross signal #1', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) MA cross signal #1 Applied")
            }
        }
    }
}

#MA cross
$button5_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (Button2EMACross_2 -filePath $item) {
                [System.Windows.Forms.MessageBox]::Show('MA cross signal #2 Applied', 'MA cross signal #2', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) MA cross signal #2 Applied")
            }
        }
    }
}

#BollingerBands 1
$button6_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonBollingerBands -FilePath $item -Number "1") {
                [System.Windows.Forms.MessageBox]::Show('BollingerBands #1 Applied', 'BollingerBands #1', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) BollingerBands #1 Applied")
            }
        }
    }
}

#BollingerBands 2
$button7_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonBollingerBands -FilePath $item -Number "2") {
                [System.Windows.Forms.MessageBox]::Show('BollingerBands #2 Applied', 'BollingerBands #2', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) BollingerBands #2 Applied")
            }
        }
    }
}

#BollingerBands 3
$button8_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonBollingerBands -FilePath $item -Number "3") {
                [System.Windows.Forms.MessageBox]::Show('BollingerBands #3 Applied', 'BollingerBands #3', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) BollingerBands #3 Applied")
            }
        }
    }
}

#Keltner Channel 1
$button9_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonKeltnerChannel -FilePath $item -Number "1") {
                [System.Windows.Forms.MessageBox]::Show('Keltner Channel #1 Applied', 'Keltner Channel #1', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Keltner Channel #1 Applied")
            }
        }
    }
}

#Keltner Channel 2
$button10_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonKeltnerChannel -FilePath $item -Number "2") {
                [System.Windows.Forms.MessageBox]::Show('Keltner Channel #2 Applied', 'Keltner Channel #2', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Keltner Channel #2 Applied")
            }
        }
    }
}

#Keltner Channel 3
$button11_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonKeltnerChannel -FilePath $item -Number "3") {
                [System.Windows.Forms.MessageBox]::Show('Keltner Channel #3 Applied', 'Keltner Channel #3', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Keltner Channel #3 Applied")
            }
        }
    }
}

#STARC Bands 1
$button12_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonSTARC -FilePath $item -Number "1") {
                [System.Windows.Forms.MessageBox]::Show('Stoller Average Range Channel #1 Applied', 'Stoller Average Range Channel #1', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Stoller Average Range Channel #1 Applied")
            }
        }
    }
}

#STARC Bands 2
$button13_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonSTARC -FilePath $item -Number "2") {
                [System.Windows.Forms.MessageBox]::Show('Stoller Average Range Channel #2 Applied', 'Stoller Average Range Channel #2', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Stoller Average Range Channel #2 Applied")
            }
        }
    }
}

#STARC Bands 3
$button14_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonSTARC -FilePath $item -Number "3") {
                [System.Windows.Forms.MessageBox]::Show('Stoller Average Range Channel #3 Applied', 'Stoller Average Range Channel #3', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Stoller Average Range Channel #3 Applied")
            }
        }
    }
}

#Custom Indy 1
$button15_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonCustomIndy_X -FilePath $item -Number "1" -Name $comboBox1.SelectedItem.ToString() ) {
                [System.Windows.Forms.MessageBox]::Show('CustomIndy #1 Applied', 'CustomIndy #1', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) CustomIndy #1 Applied")
            }
        }
    }
}

#Custom Indy 2
$button16_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonCustomIndy_X -FilePath $item -Number "2" -Name $comboBox2.SelectedItem.ToString()) {
                [System.Windows.Forms.MessageBox]::Show('CustomIndy #2 Applied', 'CustomIndy #2', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) CustomIndy #2 Applied")
            }
        }
    }
}

#Custom Indy 3
$button163_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonCustomIndy_X -FilePath $item -Number "3" -Name $comboBox3.SelectedItem.ToString()) {
                [System.Windows.Forms.MessageBox]::Show('CustomIndy #3 Applied', 'CustomIndy #3', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) CustomIndy #3 Applied")
            }
        }
    }
}

# Detect GRID
$button17_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (ButtonDetectGRID -filePath $item) {
                [System.Windows.Forms.MessageBox]::Show('Strategy GRID', 'Strategy GRID', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Strategy GRID")
            }
            else {
                [System.Windows.Forms.MessageBox]::Show('Strategy using INDICATORS', 'Strategy INDICATORS', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Strategy using INDICATORS")
            }
        }
    }
}

# Convert GRID
$button18_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            $Result = [System.Windows.Forms.MessageBox]::Show('Are you sure you want to convert the strategy to GRID?', 'Convert Strategy to GRID?', 4, 32)
            if ($Result -eq 6) {
                ButtonConvertToGRID -filePath $item
                [System.Windows.Forms.MessageBox]::Show('Strategy converted to GRID', 'Strategy converted GRID', 0, 64)
                $statusBar.Text = ("$($listBox.Items.Count) Strategy converted to GRID")
            }
        }
    }
}

# Drag And Drop CP EA
$listBox_DragOver = [System.Windows.Forms.DragEventHandler] {
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = 'Copy'
    }
    else {
        $_.Effect = 'None'
    }
}

# Drag And Drop CP EA
$listBox_DragDrop = [System.Windows.Forms.DragEventHandler] {
    foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) {
        $listBox.Items.Add($filename)
    }
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}


### Wire up events ###
$button.Add_Click($button_Click)
$button2.Add_Click($button2_Click)
$button3.Add_Click($button3_Click)
$button4.Add_Click($button4_Click)
$button5.Add_Click($button5_Click)
$button6.Add_Click($button6_Click)
$button7.Add_Click($button7_Click)
$button8.Add_Click($button8_Click)
$button9.Add_Click($button9_Click)
$button10.Add_Click($button10_Click)
$button11.Add_Click($button11_Click)
$button12.Add_Click($button12_Click)
$button13.Add_Click($button13_Click)
$button14.Add_Click($button14_Click)
#Apply CustomIndy
$button15.Add_Click($button15_Click)
$button16.Add_Click($button16_Click)
$button163.Add_Click($button163_Click)
#GRID
$button17.Add_Click($button17_Click)
$button18.Add_Click($button18_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)


#### Show form ###
[void] $form.ShowDialog()
