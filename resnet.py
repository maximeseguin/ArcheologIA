import torch
import torchvision
from torchvision import transforms


import torch.nn as nn
import torch.optim as optim
from torchvision.models import resnet50

# conda install scikit-learn
from sklearn.metrics import classification_report

from sklearn.metrics import confusion_matrix
import seaborn as sns # conda install seaborn
import matplotlib.pyplot as plt

def main():
    transform = transforms.Compose([transforms.ToTensor(),
                                    transforms.Normalize((0.485, 0.456, 0.406), (0.229, 0.224, 0.225))])
    train_data = torchvision.datasets.ImageFolder(root="train/", transform=transform)
    test_data = torchvision.datasets.ImageFolder(root="test/", transform=transform)

    # Define the dataloaders
    train_loader = torch.utils.data.DataLoader(train_data, batch_size=16, shuffle=True, num_workers=2)
    test_loader = torch.utils.data.DataLoader(test_data, batch_size=16, shuffle=False, num_workers=2)

    print(f"Nombre de classes: {len(train_data.classes)}") 
    print(f"Classes: {train_data.classes}") 
    print(f"Nombre d'échantillons d'entraînement: {len(train_data)}") 
    print(f"Nombre d'échantillons de test: {len(test_data)}")

    model = resnet50(weights=torchvision.models.ResNet50_Weights.DEFAULT)
    num_features = model.fc.in_features
    model.fc = nn.Linear(num_features, len(train_data.classes))

    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.00001)


    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    model = model.to(device)

    # Define the number of epochs
    num_epochs = 2

    # Train the model
    for epoch in range(num_epochs):
        # Train the model on the training set
        model.train()
        
        train_loss = 0.0
        for i, (inputs, labels) in enumerate(train_loader):
            
            # Move the data to the device
            inputs = inputs.to(device)
            labels = labels.to(device)

            # Zero the parameter gradients
            optimizer.zero_grad()

            # Forward + backward + optimize
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            # Update the training loss
            train_loss += loss.item() * inputs.size(0)


        

        # Evaluate the model on the test set
        model.eval()
        test_loss = 0.0
        test_acc = 0.0

        all_labels = []  # Initialize the list to store all labels
        all_preds = []   # Initialize the list to store all predictions

        with torch.no_grad():
            for i, (inputs, labels) in enumerate(test_loader):
                # Move the data to the device
                inputs = inputs.to(device)
                labels = labels.to(device)

                # Forward
                outputs = model(inputs)
                loss = criterion(outputs, labels)

                # Update the test loss and accuracy
                test_loss += loss.item() * inputs.size(0)
                _, preds = torch.max(outputs, 1)
                test_acc += torch.sum(preds == labels.data)

                # Append the labels and predictions to the lists
                all_labels.extend(labels.cpu().numpy())  # Move labels to CPU and convert to numpy
                all_preds.extend(preds.cpu().numpy())    # Move preds to CPU and convert to numpy


        # Print the training and test loss and accuracy
        train_loss /= len(train_data)
        test_loss /= len(test_data)
        test_acc = test_acc.double() / len(test_data)
        print(f"Epoch [{epoch + 1}/{num_epochs}] Train Loss: {train_loss:.4f} Test Loss: {test_loss:.4f} Test Acc: {test_acc:.4f}")

    # Print classification report and confusion matrix after training
    class_names = train_data.classes
    print(classification_report(all_labels, all_preds, target_names=class_names))

    cm = confusion_matrix(all_labels, all_preds)
    sns.heatmap(cm, annot=True, fmt='d', xticklabels=class_names, yticklabels=class_names)
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.title('Confusion Matrix')
    plt.show()

if __name__ == '__main__':
    main()