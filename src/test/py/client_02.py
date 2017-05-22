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
print("############    客户端_2   #####################")
t.start()

# 客户端信息 begin ##########
client_id = 2 
register = {'cmd':1, 'username':'yw', 'password':'ist'}
login = {'cmd':2, 'id': client_id , 'password':'ist'}
# 客户端信息 end   ##########

while True:                                           #接受多次数据

    cmd = input('请输入命令：')                 #接收数据

    if cmd == "0" or cmd == 0:
        break

    if cmd == "1" or cmd == 1:
        s.send(json.dumps(register))

    if cmd == "2" or cmd == 2:
        s.send(bytes(json.dumps(login)))

    if cmd == "3" or cmd == 3:
        to_type = input('单聊1 or  群聊2?')
        to_id = input('对方的id')
        data = input('请输入要发送的语句')
        message = {'cmd': 3, 'to_type': to_type, 'to_id': to_id, 'data': data}
        s.send(bytes(json.dumps(message)))

    if cmd == "4" or cmd == 4:
        new_friend_id = input("请输入对方的id")
        message = {'cmd': 4, 'new_friend_id': new_friend_id}
        s.send(bytes(json.dumps(message)))

    if cmd == "5" or cmd == 5:
        to_id = input("请输入对方的id")
        message = {'cmd': 5, 'to_id': to_id}
        s.send(bytes(json.dumps(message)))

s.close()                                             #关闭socket
