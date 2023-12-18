#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#include <inttypes.h>

int main()
{
    HANDLE hSerial;
    DCB dcbSerialParams = {0};
    COMMTIMEOUTS timeouts = {0};
    char buffer[24];

    // Open the serial port
    hSerial = CreateFile(_T("\\\\.\\COM18"), GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if (hSerial == INVALID_HANDLE_VALUE)
    {
        fprintf(stderr, "Error opening serial port\n");
        return 1;
    }

    // Set the serial port parameters
    dcbSerialParams.DCBlength = sizeof(dcbSerialParams);
    if (!GetCommState(hSerial, &dcbSerialParams))
    {
        fprintf(stderr, "Error getting serial port state\n");
        CloseHandle(hSerial);
        return 1;
    }

    dcbSerialParams.BaudRate = CBR_115200;   // Change this to the desired baud rate
    dcbSerialParams.ByteSize = 8;
    dcbSerialParams.StopBits = ONESTOPBIT;
    dcbSerialParams.Parity = NOPARITY;

    if (!SetCommState(hSerial, &dcbSerialParams))
    {
        fprintf(stderr, "Error setting serial port state\n");
        CloseHandle(hSerial);
        return 1;
    }

    // Set timeouts
    timeouts.ReadIntervalTimeout = 50;
    timeouts.ReadTotalTimeoutConstant = 50;
    timeouts.ReadTotalTimeoutMultiplier = 10;
    timeouts.WriteTotalTimeoutConstant = 50;
    timeouts.WriteTotalTimeoutMultiplier = 10;

    if (!SetCommTimeouts(hSerial, &timeouts))
    {
        fprintf(stderr, "Error setting timeouts\n");
        CloseHandle(hSerial);
        return 1;
    }

    DWORD bytesRead;
    uint32_t speed = 0;
    uint32_t pulses = 0;
    char temp = ' ';
    while (1) {
        if (!ReadFile(hSerial, buffer, 24, &bytesRead, NULL)) {
            fprintf(stderr, "Error reading from serial port\n");
            //break;
        }

        // Process the received data (e.g., print to console)
        for (DWORD i = 0; i < bytesRead; i++) {
            if (buffer[i] == '\n') {

                //memcpy(&speed, buffer + i + 2, 4);
                //temp = buffer[i+2];
                speed = (buffer[i + 2] << 24) +
                (buffer[i + 3] << 16) +
                (buffer[i + 4] << 8) +
                buffer[i + 5];

                pulses = ((buffer[i + 7] << 24) & 0xFF000000) +
                ((buffer[i + 8] << 16) & 0xFF0000) +
                ((buffer[i + 9] << 8) & 0xFF00) +
                (buffer[i + 10] & 0xFF);

                printf("Speed: %d | Pulse Counter: %u \n", speed, pulses);
                //printf("| HEX: %X %X %X %X\n", buffer[i + 7], buffer[i + 8], buffer[i + 9], buffer[i + 10]);
                // Handle the line as needed

                // Reset the buffer
                memset(buffer, 0, sizeof(buffer));
            }
        }
    }

    // Close the serial port
    CloseHandle(hSerial);

    return 0;
}
