import pandas

# read in the trace file only look at channel 0
data = pandas.read_csv('ramulator_access_trace.txt').query('channel==0')

# get a 'send' table and 'recv' table
send = data.query('request=="send"')
recv = data.query('request=="recv"')
send.set_index('address')
recv.set_index('address')

# merge on 'address' and calculate latency
merged = pandas.merge(send, recv, on='address')
merged['latency'] = merged['time_y']-merged['time_x']
print("mean latency = {} ns".format(merged['latency'].mean() * 1e-3))
print("median latency = {} ns".format(merged['latency'].median() * 1e-3))
print("min latency = {} ns".format(merged['latency'].min() * 1e-3))
print("max latency = {} ns".format(merged['latency'].max() * 1e-3))
