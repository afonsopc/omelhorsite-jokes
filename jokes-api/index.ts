function generateRandomNumber(): number {
    return Math.floor(Math.random() * 100);
}

const fruits: string[] = ['apple', 'banana', 'orange'];

interface Person {
    name: string;
    age: number;
    hobbies: string[];
}

class Animal {
    constructor(public name: string, public age: number) { }

    makeSound(): void {
        console.log('Roar!');
    }
}

const myAnimal: Animal = new Animal('Lion', 5);
myAnimal.makeSound();

const addNumbers = (a: number, b: number): number => {
    return a + b;
};

const result: number = addNumbers(10, 20);
console.log(result);

const isEven = (num: number): boolean => {
    return num % 2 === 0;
};

console.log(isEven(4));

const greet = (name: string): void => {
    console.log(`Hello, ${name}!`);
};

greet('John');

const capitalize = (str: string): string => {
    return str.charAt(0).toUpperCase() + str.slice(1);
};

console.log(capitalize('hello'));

const multiply = (a: number, b: number): number => a * b;

console.log(multiply(5, 6));