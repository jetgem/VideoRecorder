# VideoRecorder


Instagram like Video Rcorder Demo.

#### Dirty Fix for PBJVision
You need to modify some code of the following function in PBJVision.m
````
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
````

Find the code and change as followings:
````
    [self _enqueueBlockOnMainQueue:^{
        if ([_delegate respondsToSelector:@selector(vision:didCaptureVideoSampleBuffer:)]) {
            [_delegate vision:self didCaptureVideoSampleBuffer:nil];
        }
    }];
````

### Todos

 - Make code beautiful

License
----

MIT


