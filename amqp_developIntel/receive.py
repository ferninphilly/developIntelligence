#!/usr/bin/env python
import pika
import time

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='mailbox')

def callback(ch, method, properties, body):
    print(" [x] Received %r" % body)

channel.basic_consume(callback,
                      queue='mailbox',
                      no_ack=True)


print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()

