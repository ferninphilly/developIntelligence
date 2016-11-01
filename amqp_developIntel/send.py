#!/usr/bin/env python
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='mailbox')

channel.basic_publish(exchange='',
                      routing_key='mailbox',
                      body='The Times They are a changin')
print(" [x] Sent 'The Times They are a changin'")
connection.close()
