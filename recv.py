import serial
import time
import asyncio
import keyboard
import sys
import asyncio

BAUD = 115200
running = True

async def keypress_listener(queue, stop_event):
    message = " "
    while not stop_event.is_set():
        try:
            while True:
                if keyboard.is_pressed('q'):
                    await queue.put("q")
                if keyboard.is_pressed('r'):
                    await queue.put("r")
                if keyboard.is_pressed('n'):
                    await queue.put("n")
                    
                await queue.put(None)    
                await asyncio.sleep(0.001)
        except asyncio.CancelledError:
            pass
        except SystemExit:
            pass

async def read_values(queue, stop_event):
    ser = serial.Serial('COM18', baudrate=BAUD)
    data = b" "
    try:
        last_value = 0
        last_pulses = 0
        pulses = 0
        last_time = time.perf_counter()
        dxdt_max = 1
        dxdt = 0

        while running:
            while data[0] != 83:
                data = ser.readline()

            value = int.from_bytes(data[1:5], byteorder='big')
            pulses = int.from_bytes(data[6:10], byteorder='big')

            dxdt = (pulses - last_pulses) / (time.perf_counter() - last_time)

            print(f"speed: {value}, pulses: {pulses}, dx/dt: {dxdt}, pulses_max: {dxdt_max:.2f}, data: {data[6:10]}")

            last_value, last_pulses = value, pulses
            last_time = time.perf_counter()

            if abs(dxdt) > dxdt_max:
                dxdt_max = dxdt

            ser.flushInput()
            ser.flushOutput()
            data = b" "
            
            message = await queue.get()
            if message == "q":
                break
            elif message == "r":
                ser.write(b"R")
            elif message == "n":
                ser.write(b"N")
            
            await asyncio.sleep(0.01)

    except asyncio.CancelledError:
        pass
    finally:
        ser.close()
        stop_event.set()
        return
        
async def principal():
    queue = asyncio.Queue()
    stop_event = asyncio.Event()
    
    producer_task = asyncio.create_task(keypress_listener(queue=queue, stop_event=stop_event))
    consumer_task = asyncio.create_task(read_values(queue=queue, stop_event=stop_event))
    
    await asyncio.gather(producer_task, consumer_task)
    

if __name__ == "__main__":
    asyncio.run(principal())

