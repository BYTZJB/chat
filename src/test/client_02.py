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
print("客户端_2#####################")
t.start()

register = {'cmd':'1', 'username':'yw', 'password':'ist'}
login = {'cmd':'2', 'password':'ist'}

while True:                                           #接受多次数据

    data = input('请输入要发送的数据：')                 #接收数据

    if data == "0" or data == 0:
        break

    if data == "1" or data == 1:
        s.send(json.dumps(register))

    if data == "2" or data == 2:
        s.send(bytes(json.dumps(login)))

    if data == "3" or data == 3:
        message = input('请输入要发送的语句')
        chat_context = {'cmd': '3', 'id': '2', 'to_type': '1', 'to_id': '1', 'data': message}
        s.send(bytes(json.dumps(chat_context)))

s.close()                                             #关闭socket
