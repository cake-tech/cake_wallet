class IoniaCategory {
  const IoniaCategory({
    required this.index,
    required this.title,
    required this.ids,
    required this.iconPath});

  static const allCategories = <IoniaCategory>[all, apparel, onlineOnly, food, entertainment, delivery, travel];
  static const all = IoniaCategory(index: 0, title: 'All', ids: [], iconPath: 'assets/images/category.png');
  static const apparel = IoniaCategory(index: 1, title: 'Apparel', ids: [1], iconPath: 'assets/images/tshirt.png');
  static const onlineOnly = IoniaCategory(index: 2, title: 'Online Only', ids: [13, 43], iconPath: 'assets/images/global.png');
  static const food = IoniaCategory(index: 3, title: 'Food', ids: [4], iconPath: 'assets/images/food.png');
  static const entertainment = IoniaCategory(index: 4, title: 'Entertainment', ids: [5], iconPath: 'assets/images/gaming.png');
  static const delivery = IoniaCategory(index: 5, title: 'Delivery', ids: [114, 109], iconPath: 'assets/images/delivery.png');
  static const travel = IoniaCategory(index: 6, title: 'Travel', ids: [12], iconPath: 'assets/images/airplane.png');


  final int index;
  final String title;
  final List<int> ids;
  final String iconPath;
}
