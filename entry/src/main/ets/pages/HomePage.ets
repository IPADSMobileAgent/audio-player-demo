@Entry @Component
struct HomePage {
  build() {
    Column() {
      Button('Button')
      Row() {
        Checkbox()
        Text('Text')
      }
      TextInput()
    }
  }
}
