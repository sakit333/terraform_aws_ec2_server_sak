#!/bin/bash

# Install Apache Maven 3.9.11

# Variables
MAVEN_VERSION=3.9.11
MAVEN_ARCHIVE=apache-maven-$MAVEN_VERSION-bin.tar.gz
MAVEN_FOLDER=apache-maven-$MAVEN_VERSION
INSTALL_PATH=$HOME/maven

# Download Maven
wget https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_ARCHIVE}

# Extract archive
tar -zxvf $MAVEN_ARCHIVE

# Remove archive
rm -f $MAVEN_ARCHIVE

# Rename extracted folder
mv $MAVEN_FOLDER $INSTALL_PATH

# Add Maven to PATH in ~/.bashrc if not already added
if ! grep -q 'export PATH=\$HOME/maven/bin:\$PATH' ~/.bashrc; then
    echo 'export PATH=$HOME/maven/bin:$PATH' >> ~/.bashrc
fi

# Apply the updated PATH for current session
export PATH=$HOME/maven/bin:$PATH

# Verify installation
echo "Maven installation complete. Version:"
mvn --version || echo "Maven not found. Try opening a new terminal or run 'source ~/                       .bashrc'"

# Final reminder
echo ""
echo "Run the following to use 'mvn' in new terminals or shells:"
echo "   source .bashrc"
echo "after check with mvn --version in root user"