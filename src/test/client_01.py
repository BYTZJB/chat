#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2017 bytzjb <bytzjb@brucedeiMac.local>
#
# Distributed under terms of the MIT license.

import socket
import json
import threading 


s = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #创建一个socket


s.connect(('127.0.0.1', 5678))                       #建立连接

def receive_message(conn):
    data = conn.recv(1024)
    print("\n")
    print(data)
    receive_message(conn)

t = threading.Thread(target=receive_message, args = (s,), name="Receive Message")
print("############    客户端_1   #####################")
t.start()

register = {'cmd':'1', 'username':'zst', 'password':'iyw'}
login = {'cmd':'2', 'id': '1', 'password':'iyw'}

while True:                                           #接受多次数据

    cmd = input('请输入要发送的数据：')                 #接收数据

    if cmd == "0" or cmd == 0:
        break

    if cmd == "1" or cmd == 1:
        s.send(json.dumps(register))
        continue

    if cmd == "2" or cmd == 2:
        s.send(bytes(json.dumps(login)))
        continue

    if cmd == "3" or cmd == 3:
        to_type = str(input('单聊1 群聊2'))
        to_id = str(input('对方的id'))
        message = input('请输入要发送的语句')
        chat_context = {'cmd': '3', 'id': '1', 'to_type': to_type, 'to_id': to_id, 'data': message}
        s.send(bytes(json.dumps(chat_context)))

    if True:
        continue

s.close()                                             #关闭socket
