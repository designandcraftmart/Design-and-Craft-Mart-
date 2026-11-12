export type Product = { id:string; name:string; category:string; price:number; oldPrice:number; image:string; description:string; checkoutUrl?:string; featured?:boolean };
export const products: Product[] = [
 {id:'frame',name:'Custom Photo Frame',category:'Photo Frames',price:349,oldPrice:499,image:'/images/photo-frame.jpg',description:'A personalised photo frame made to display a favourite memory.',featured:true},
 {id:'mug',name:'Custom Mug',category:'Mugs',price:299,oldPrice:399,image:'/images/mug.jpg',description:'A custom printed mug for everyday moments.',featured:true},
 {id:'glass',name:'Personalised Glass',category:'Glasses',price:299,oldPrice:399,image:'/images/glass.jpg',description:'A personalised glass with your chosen photo or artwork.',featured:true},
 {id:'tshirt',name:'Custom T-Shirt',category:'T-Shirts',price:499,oldPrice:699,image:'/images/tshirt.jpg',description:'A custom printed T-shirt. Share your design idea before ordering.',featured:true},
 {id:'gift-set',name:'Personalised Gift Set',category:'Gift Sets',price:899,oldPrice:1299,image:'/images/gift-set.jpg',description:'A thoughtful gift set with personalised items.',featured:true},
 {id:'gift',name:'Custom Gift',category:'Personalised Gifts',price:599,oldPrice:799,image:'/images/gift.jpg',description:'A personalised gift prepared around your idea.',featured:true}
];
export const categories = [
 {name:'Photo Frames',icon:'▧',image:'/images/photo-frame.jpg'}, {name:'Mugs',icon:'▱',image:'/images/mug.jpg'},
 {name:'Glasses',icon:'♧',image:'/images/glass.jpg'}, {name:'T-Shirts',icon:'♧',image:'/images/tshirt.jpg'},
 {name:'Gift Sets',icon:'♙',image:'/images/gift-set.jpg'}, {name:'Personalised Gifts',icon:'◇',image:'/images/gift.jpg'}
];
export const money=(n:number)=>`₹${n.toLocaleString('en-IN')}`;
