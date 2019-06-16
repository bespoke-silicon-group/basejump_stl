#!/usr/bin/python

import sys

def to_binary( num, radix, length ):
  return ('{0:0%db}' % length).format( int( str(num), radix ) )

class bsg_fsb_node_trace_replay_writer:
  
  # send_els = number of elements to send
  # send_widths = list of widths for each send element
  # recv_els = number of elements to send
  # recv_widths = list of widths for each send element
  # spool = set to fid to dump directly to file
  def __init__( self, send_els, send_widths, recv_els, recv_widths, spool=sys.stdout ):
    self.send_els = send_els
    self.send_widths = send_widths
    self.recv_els = recv_els
    self.recv_widths = recv_widths
    self.trace_width = max( sum(self.send_widths), sum(self.recv_widths) )
    self.spool = spool

  def comment( self, c ):
    self.spool.write( '# %s\n' % c )

  def nop( self ):
    self.spool.write( '0000___%s\n' % ('0' * self.trace_width) )

  def send_hex( self, data ):
    send_str = '_'.join( [to_binary(d, 16, w) for d,w in zip(list(data), self.send_widths)] )
    padding = '0' * (self.trace_width - sum(self.send_widths))
    self.spool.write( '0001___%s___%s\n' % (padding, send_str) )

  def send_dec( self, data ):
    send_str = '_'.join( [to_binary(d, 10, w) for d,w in zip(list(data), self.send_widths)] )
    padding = '0' * (self.trace_width - sum(self.send_widths))
    self.spool.write( '0001___%s___%s\n' % (padding, send_str) )

  def send_bin( self, data ):
    send_str = '_'.join( [to_binary(d, 2, w) for d,w in zip(list(data), self.send_widths)] )
    padding = '0' * (self.trace_width - sum(self.send_widths))
    self.spool.write( '0001___%s___%s\n' % (padding, send_str) )

  def recv_hex( self, data ):
    recv_str = '_'.join( [to_binary(d, 16, w) for d,w in zip(list(data), self.recv_widths)] )
    padding = '0' * (self.trace_width - sum(self.recv_widths))
    self.spool.write( '0010___%s___%s\n' % (padding, recv_str) )

  def recv_dec( self, data ):
    recv_str = '_'.join( [to_binary(d, 10, w) for d,w in zip(list(data), self.recv_widths)] )
    padding = '0' * (self.trace_width - sum(self.recv_widths))
    self.spool.write( '0010___%s___%s\n' % (padding, recv_str) )

  def recv_bin( self, data ):
    recv_str = '_'.join( [to_binary(d, 2, w) for d,w in zip(list(data), self.recv_widths)] )
    padding = '0' * (self.trace_width - sum(self.recv_widths))
    self.spool.write( '0010___%s___%s\n' % (padding, recv_str) )
    
  def done( self ):
    self.spool.write( '0011___%s\n' % ('0' * self.trace_width) )

  def finish( self ):
    self.spool.write( '0100___%s\n' % ('0' * self.trace_width) )

  def wait( self, cycles ):
    self.spool.write( '0110___%s\n' % to_binary(cycles, 10, self.trace_width) )
    self.spool.write( '0101___%s\n' % ('0' * self.trace_width) )

#end class bsg_fsb_node_trace_replay_writer

