from mem_pattern_trace import *
syscall(mem_pattern_trace, TRACE_START | TRACE_AUTO)
import gc
gc.disable()
import os
os.environ["OMP_NUM_THREADS"] = "1"
import resource
import torch
torch.set_num_threads(1)
import numpy as np
#import torchvision
#import torchvision.models as models
from PIL import Image
import torch.nn as nn
import torch.nn.functional as F
from torch import Tensor
class MNISTNet(nn.Module):
    """Simple CNN adapted from Pytorch's 'Basic MNIST Example'."""

    def __init__(self) -> None:
        super(MNISTNet, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 1)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.fc1 = nn.Linear(784, 128)
        self.fc2 = nn.Linear(128, 128)
        self.fc3 = nn.Linear(128, 10)

    def forward(self, x: Tensor) -> Tensor:
        """Compute forward pass.

        Parameters
        ----------
        x: Tensor
            Mini-batch of shape (N,28,28) containing images from MNIST dataset.


        Returns
        -------
        output: Tensor
            The probability density of the output being from a specific class given the input.

        """
        #x = self.conv1(x)
        #x = F.relu(x)
        #x = self.conv2(x)
        #x = F.relu(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.sigmoid(x)
        x = self.fc2(x)
        x = F.sigmoid(x)
        x = self.fc3(x)
        output = F.log_softmax(x, dim=1)
        return output

model = MNISTNet() #torch.hub.load('pytorch/vision', 'vgg16', pretrained=True)
model.eval()

from torchvision import transforms
preprocess = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])
alexnet = model#models.vgg16(pretrained=True)

input_image = Image.open("dog.jpg")

input_tensor = preprocess(input_image).unsqueeze(0)
input_batch = input_tensor.unsqueeze(0) # create a mini-batch as expected by the model
with torch.no_grad():
        input_tensor = torch.zeros(1000, 1, 28, 28)
        output = [0,1,2]
        output = alexnet(input_tensor)

syscall(mem_pattern_trace, TRACE_END)

rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
print("Max RSS: %d kb or %d pages" % (rss, rss/4))
#print(np.argmax(torch.nn.functional.softmax(output[0], dim=0)))
