*** Settings ***
Documentation       Order robots from RobotSpareBin Industies Inc
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screensgot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Desktop
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs


*** Tasks ***
Order robots from the RobotSpareBin Industies Inc
    Open the RSI order website
    Close the annoying modal
    ${csv_url}=    Ask user for CSV file
    Get the CSV file    ${csv_url}
    ${orders}=    Read table from CSV    orders.csv    header=true
    FOR    ${order}    IN    @{orders}
        Order robots and store receipts    ${order}
    END
    Creating a ZIP Archive of the files
    [Teardown]    Close the browser


*** Keywords ***
Open the RSI order website
    ${url}=    Get Secret    urls
    Open Available Browser    ${url}[platform_url]

Close the annoying modal
    Click Element If Visible    class:btn-dark

Ask user for CSV file
    Add heading    Link to the CSV file
    Add text    hint: https://robotsparebinindustries.com/orders.csv
    Add text input
    ...    name=csv_url
    ...    label=Paste the link to the CSV file
    ...    placeholder=A link starts with http:// or https://
    ${response}=    Run dialog
    RETURN    ${response.csv_url}

Get the CSV file
    [Arguments]    ${csv_url}
    Download    ${csv_url}    overwrite=True

Order robots and store receipts
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    Preview
    Submit the form
    Export the receipt as a PDF and add the image    ${order}[Order number]
    Click Button    id:order-another
    Close the annoying modal

Submit the form
    Click Button    Order
    ${contains}=    Does Page Contain Element    id:receipt
    IF    ${contains} == False    Submit the form

Export the receipt as a PDF and add the image
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}orders/order_${order_number}_receipt.pdf
    Screenshot    css:div#robot-preview-image    ${OUTPUT_DIR}${/}orders/robot_${order_number}_screenshot.png
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}orders/robot_${order_number}_screenshot.png
    Open Pdf    ${OUTPUT_DIR}${/}orders/order_${order_number}_receipt.pdf
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}orders/order_${order_number}_receipt.pdf    true

Creating a ZIP Archive of the files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders    orders.zip

Close the browser
    Close Browser
