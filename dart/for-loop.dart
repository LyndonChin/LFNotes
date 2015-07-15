var callbacks = [];

for (int i = 0; i < 5; i++) {
    callbacks.add(() => print(i));
}

callbacks.forEach((c) => c());
