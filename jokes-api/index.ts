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

const reverseString = (str: string): string => {
    return str.split('').reverse().join('');
};
console.log(reverseString('hello'));

const calculateFactorial = (num: number): number => {
    if (num === 0 || num === 1) {
        return 1;
    } else {
        return num * calculateFactorial(num - 1);
    }
};
console.log(calculateFactorial(5));

const isPalindrome = (str: string): boolean => {
    const reversedStr = str.split('').reverse().join('');
    return str === reversedStr;
};
console.log(isPalindrome('madam'));

const findMaxNumber = (numbers: number[]): number => {
    let max = numbers[0];
    for (let i = 1; i < numbers.length; i++) {
        if (numbers[i] > max) {
            max = numbers[i];
        }
    }
    return max;
};
console.log(findMaxNumber([10, 5, 20, 15]));

const calculateAverage = (numbers: number[]): number => {
    const sum = numbers.reduce((acc, curr) => acc + curr, 0);
    return sum / numbers.length;
};
console.log(calculateAverage([1, 2, 3, 4, 5]));

const removeDuplicates = (arr: any[]): any[] => {
    return [...new Set(arr)];
};
console.log(removeDuplicates([1, 2, 2, 3, 4, 4, 5]));

const formatDate = (date: Date): string => {
    const options = { year: 'numeric', month: 'long', day: 'numeric' };
    return date.toLocaleDateString('en-US', options);
};
console.log(formatDate(new Date()));