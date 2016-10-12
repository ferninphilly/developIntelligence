#!/usr/bin/env python
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters(
               'localhost'))
channel = connection.channel()
channel.queue_declare(queue='mailbox')
channel.basic_publish(exchange='',
                      routing_key='mailbox',
                      body='Hello Mother! Hello Father!')
print(" [x] Sent 'Hello World!'")
connection.close()