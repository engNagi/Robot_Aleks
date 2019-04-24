# FILE: auktion_keyword.resource

#  ███████╗███████╗████████╗████████╗██╗███╗   ██╗ ██████╗ ███████╗
#  ██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██║████╗  ██║██╔════╝ ██╔════╝
#  ███████╗█████╗     ██║      ██║   ██║██╔██╗ ██║██║  ███╗███████╗
#  ╚════██║██╔══╝     ██║      ██║   ██║██║╚██╗██║██║   ██║╚════██║
#  ███████║███████╗   ██║      ██║   ██║██║ ╚████║╚██████╔╝███████║
#  ╚══════╝╚══════╝   ╚═╝      ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝
*** Settings ***
Documentation     Frequenzauktion 5G 2019 Datacollector with ${BROWSER}
Library           SeleniumLibrary
Library           OperatingSystem
Library           String
Library           Collections
Library           robot.libraries.DateTime
Resource          vars.txt


#  ██╗  ██╗███████╗██╗   ██╗██╗    ██╗ ██████╗ ██████╗ ██████╗ ███████╗
#  ██║ ██╔╝██╔════╝╚██╗ ██╔╝██║    ██║██╔═══██╗██╔══██╗██╔══██╗██╔════╝
#  █████╔╝ █████╗   ╚████╔╝ ██║ █╗ ██║██║   ██║██████╔╝██║  ██║███████╗
#  ██╔═██╗ ██╔══╝    ╚██╔╝  ██║███╗██║██║   ██║██╔══██╗██║  ██║╚════██║
#  ██║  ██╗███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝███████║
#  ╚═╝  ╚═╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝
*** Keywords ***

Open Browser
    # Store starttime as a global variable
    ${STARTTIME}=           get time
    set global variable     ${STARTTIME_G}      ${STARTTIME}

    # Open Browser and resize the window
    create webdriver        ${BROWSER}
    set window size         ${WINDOW_X}         ${WINDOW_Y}


Navigate To Main Webpage
    # Navigate to the main webpage and verify it
    Go To                   ${URLMAIN}
    Title Should Be         Bundesnetzagentur - Mobilfunknetze


Get ammount of Rounds
    # Store the latest available Round in a global variable
    ${Current_Round_String}=    get text                xpath://div[@class='singleview']/h3
    @{Current_Round_Split}=     Split String            ${Current_Round_String}    separator=${SPACE}
    set global variable         ${Max_Round}            ${Current_Round_Split}[3]
    log to console              \n\nLatest available Round on the website: ${Max_Round}


Gather Data
    ${Max_Round_int}=       convert to integer  ${Max_Round}
    ${NextGatherRound}=     set variable        ${Max_Round_int+1}
    ${j_int}=               convert to integer  ${StartRound}
    ${j}=                   set variable        ${j_int}

    # Loop to cycle through the rounds
    : FOR    ${i}           IN RANGE    999

    # End the loop if there is no new data to collect
    \   run keyword if      ${StartRound}==${NextGatherRound}       run keywords
    \   ...                 log to console      \nNothing to gather. Round ${StartRound} data not available yet...
    \   ...     AND         exit for loop

    # Build the URL for the current round (j) where the data is stored in the tables
    \   ${URLROUND}=        set variable if
    \   ...     ${j}>=100   ${URLDATA}${j}.html
    \   ...     ${j}>=10    ${URLDATA}0${j}.html
    \   ...     ${j}<10     ${URLDATA}00${j}.html
    \   log to console      \nRound: ${j}
    \   log to console      ${URLROUND}

    # Navigate to the current round (j) URL and take a screenshot
    \   Go To               ${URLROUND}
    \   Screenshot          Screenshot_Round_${j}.png

    # Access the tables
    \   Get Table           ${j}    xpath://table[@class='table1 gebotsobjekte'][1]/tbody[1]/tr     data_2GHz.txt
    \   Get Table           ${j}    xpath://table[@class='table2a gebotsobjekte'][1]/tbody[1]/tr    data_36GHz.txt
    \   Get Table           ${j}    xpath://table[@class='table2b gebotsobjekte'][1]/tbody[1]/tr    data_36GHz.txt

    # End the loop if it reaches the latest available round
    \   exit for loop if    ${j}==${Max_Round}

    # Increment the current round value by one
    \   ${j}                set variable        ${j+1}

    # Create a new "vars.txt" file where the next round to collect is stored
    create file             ${CURDIR}/vars.txt            *** Variables ***\n\${StartRound}${SPACE * 4}${NextGatherRound}
    log to console          \nNext round to gather stored: ${NextGatherRound}\n
    log to console          ${CURDIR}

    # Update zip-file with all new screenshots and delete the screenshot files
    run                     zip -u ./Output/AllScreenshots.zip ./Output/Screenshot*
    run                     rm ./Output/Screenshot*

    # Create a zip-file with both csv data files and the screenshot archive
    run                     zip ./Output/Round${Max_Round_int}.zip data_2GHz.txt data_36GHz.txt ./Output/AllScreenshots.zip

    # Store endtime and calcute the runtime. Log the runtime to the console
    ${ENDTIME}=             get time
    ${RUNTIME}=             Subtract Date From Date       ${ENDTIME}    ${STARTTIME_G}      compact
    log to console          Runtime: ${RUNTIME}\n


Get Table
    [Arguments]             ${current_round}    ${xpath}     ${filename}

    # Store the ammount of rows in this table
    ${Max_Row_Table}=       get element count   ${xpath}
    log to console          \nAmmount of Rows: ${Max_Row_Table}

    # Loop to cycle through the rows
    : FOR  ${m}             IN RANGE    25
    \   ${m}                set variable        ${m+1}

    # Build the xpath to access the current row (m)
    \   ${DataXPath}=       set variable        ${xpath}\[${m}\]

    # Split the current row into single values seperated by ";" and store/return it in a variable
    \   ${DataRow}=         SplitUP             ${DataXPath}

    # Append the new collected data to the file. The table header will not be appended (${m}>=3)
    \   run keyword if      ${m}>=3             run keywords
    \   ...                 append to file      ${filename}         \n${current_round}${DataRow}
    \   ...     AND         log to console      => ${current_round}${DataRow}
    \   run keyword if      ${m}<3              log to console      ${SPACE * 3}Header - no valid data found in this row

    # End the loop if it reaches the latest available row
    \   exit for loop if    ${m}==${Max_Row_Table}


SplitUP
    [Arguments]             ${DataXPath}

    # Store the ammount of values in this row
    ${RowValues}=           get element count   ${DataXPath}/td
    log to console          Ammount of Values: ${RowValues}

    # Create a new empty variable to append the single values seperated by a ";"
    ${valuesRow}=           set variable

    # Loop to cycle through the values
    : FOR  ${n}             IN RANGE    10

    # Exit loop if there are less than four values available (no valid data row)
    \   exit for loop if    ${RowValues}<4
    \   ${n}                set variable        ${n+1}

    # Store the currnet value in a variable
    \   ${value}=           get text            ${DataXPath}/td[${n}]

    # Append the new value to a variable that stores all collected values seperated with ";"
    \   ${valuesRow}=       set variable        ${valuesRow};${value}

    # End the loop if it reaches the latest available value
    \   exit for loop if    ${n}>=${RowValues}

    # Return the collected vaules to the parrent keyword
    [Return]                ${valuesRow}


# ============================ T O O L S ==================================
Screenshot
    [Arguments]                 ${screenshotname}

    # Take a screenshot with the passed name
    capture page screenshot     ./Output/${screenshotname}