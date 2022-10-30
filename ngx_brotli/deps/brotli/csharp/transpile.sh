if ! which mvn >/dev/null; then
  echo -e '\033[01;31mMaven is not installed / configured.\033[00m'
  exit 1
fi

if ! which mono >/dev/null; then
  echo -e '\033[01;31mMono platform is not installed / configured.\033[00m'
  exit 1
fi

if ! which nuget >/dev/null; then
  echo -e '\033[01;31mNuGet compiler is not installed / configured.\033[00m'
  exit 1
fi

if ! which mcs >/dev/null; then
  echo -e '\033[01;31mC# compiler is not installed / configured.\033[00m'
  exit 1
fi

rm -rf build
mkdir build
cd build

#-------------------------------------------------------------------------------

echo -e '\033[01;33mFetching Sharpen sources.\033[00m'

git clone https://github.com/stanislaw89/sharpen.git
cd sharpen
git checkout 4f609ed42862a1f9aab1be00374ff86534a5e6d6 || exit 1

#-------------------------------------------------------------------------------

echo -e '\n\033[01;33mCompiling Sharpen.\033[00m'

mvn clean package -DskipTests
mvn dependency:copy -Dartifact=junit:junit:4.12 -DoutputDirectory=..
cd ..
cp sharpen/target/sharpencore-0.0.1-SNAPSHOT-jar-with-dependencies.jar ./sharpen.jar

#-------------------------------------------------------------------------------

echo -e '\n\033[01;33mTranspiling.\033[00m'

cd ..
java -jar build/sharpen.jar ../java/org/brotli/dec/ -cp build/junit-4.12.jar @sharpen.cfg

#-------------------------------------------------------------------------------

echo -e '\n\033[01;33mPatching.\033[00m'

# TODO: detect "dead" files, that are not generated by sharpen anymore.
cp -r build/generated/* ./

# Reflection does not work without Sharpen.cs
rm org/brotli/dec/EnumTest.cs

PATTERN='\/\/ \<\{\[INJECTED CODE\]\}\>'
CODE=$(<org/brotli/dec/BrotliInputStream.cs)
REPLACEMENT=$(<injected_code.txt)
echo "${CODE//$PATTERN/$REPLACEMENT}" > org/brotli/dec/BrotliInputStream.cs

#-------------------------------------------------------------------------------

echo -e '\n\033[01;33mDowloading dependencies.\033[00m'

cd build
nuget install NUnit -Version 3.6.1
nuget install NUnit.ConsoleRunner -Version 3.6.1
cd ..

#-------------------------------------------------------------------------------

echo -e '\n\033[01;33mCompiling generated code.\033[00m'

SOURCES=`find org/brotli -type file ! -path "*Test.cs"`
TESTS_SOURCES=`find org/brotli -type file -path "*Test.cs"`

mcs $SOURCES -target:library -out:build/brotlidec.dll
mcs $SOURCES $TESTS_SOURCES -target:library -out:build/brotlidec_test.dll -r:build/NUnit.3.6.1/lib/net45/nunit.framework.dll

#-------------------------------------------------------------------------------

echo -e '\n\033[01;33mRunning tests.\033[00m'

export MONO_PATH=$MONO_PATH:`pwd`/build/NUnit.3.6.1/lib/net45
mono --debug build/NUnit.ConsoleRunner.3.6.1/tools/nunit3-console.exe build/brotlidec_test.dll

#-------------------------------------------------------------------------------

echo -e '\n\033[01;33mCleanup.\033[00m'
rm TestResult.xml
rm -rf build
