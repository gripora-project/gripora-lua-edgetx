local protocol = gr.executeScript("F/getProtocol")()
assert(protocol, "Unsupported protocol!")
return protocol
