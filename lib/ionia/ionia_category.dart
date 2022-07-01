class IoniaCategory {
  const IoniaCategory({this.title, this.ids, this.iconPath});

  static const allCategories = <IoniaCategory>[all, apparel, onlineOnly, food, entertainment, delivery, travel];
  static const all = IoniaCategory(title: 'All', ids: [], iconPath: 'assets/images/category.png');
  static const apparel = IoniaCategory(title: 'Apparel', ids: [1], iconPath: 'assets/images/tshirt.png');
  static const onlineOnly = IoniaCategory(title: 'Online Only', ids: [13, 43], iconPath: 'assets/images/global.png');
  static const food = IoniaCategory(title: 'Food', ids: [4], iconPath: 'assets/images/food.png');
  static const entertainment = IoniaCategory(title: 'Entertainment', ids: [5], iconPath: 'assets/images/gaming.png');
  static const delivery = IoniaCategory(title: 'Delivery', ids: [114, 109], iconPath: 'assets/images/delivery.png');
  static const travel = IoniaCategory(title: 'Travel', ids: [12], iconPath: 'assets/images/airplane.png');

  final String title;
  final List<int> ids;
  final String iconPath;
}
