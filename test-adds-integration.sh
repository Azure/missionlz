#!/bin/bash

# Simple validation test for MLZ with ADDS parameters
# This test validates that the bicep template compiles correctly with ADDS parameters

echo "🧪 Testing MLZ bicep template with ADDS parameters..."

# Test bicep compilation
echo "  ✓ Testing bicep compilation..."
cd /home/runner/work/missionlz/missionlz/src/bicep
if az bicep build --file mlz.bicep --stdout > /dev/null 2>&1; then
    echo "  ✅ Bicep compilation successful"
else
    echo "  ❌ Bicep compilation failed"
    exit 1
fi

# Test ADDS module compilation
echo "  ✓ Testing ADDS module compilation..."
if az bicep build --file modules/active-directory-domain-controllers.bicep --stdout > /dev/null 2>&1; then
    echo "  ✅ ADDS module compilation successful"
else
    echo "  ❌ ADDS module compilation failed"
    exit 1
fi

# Test ADDS resources module compilation
echo "  ✓ Testing ADDS resources module compilation..."
if az bicep build --file modules/active-directory-domain-controllers-resources.bicep --stdout > /dev/null 2>&1; then
    echo "  ✅ ADDS resources module compilation successful"
else
    echo "  ❌ ADDS resources module compilation failed"
    exit 1
fi

# Test parameter structure by checking generated ARM template
echo "  ✓ Testing parameter structure..."
ARM_TEMPLATE=$(az bicep build --file mlz.bicep --stdout 2>/dev/null)

# Check for ADDS parameters in generated ARM template
if echo "$ARM_TEMPLATE" | grep -q "deployActiveDirectoryDomainServices" && \
   echo "$ARM_TEMPLATE" | grep -q "addsDnsDomainName" && \
   echo "$ARM_TEMPLATE" | grep -q "addsNetbiosDomainName"; then
    echo "  ✅ ADDS parameters found in ARM template"
else
    echo "  ❌ ADDS parameters missing from ARM template"
    exit 1
fi

# Check for ADDS outputs in generated ARM template
if echo "$ARM_TEMPLATE" | grep -q "activeDirectoryDomainServicesDeployed"; then
    echo "  ✅ ADDS outputs found in ARM template"
else
    echo "  ❌ ADDS outputs missing from ARM template"
    exit 1
fi

echo "🎉 All tests passed! ADDS integration is working correctly."