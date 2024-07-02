import java.lang.Math;

public class SebastianBday {
  public static int[] birthday(int pop_size){
    int[] arr = new int[pop_size];
    for(int i = 0; i < pop_size; i++){
      arr[i] = (int)(Math.random()*365);
    }
    return arr;
  }

  
  public static int match (int pop_size){
    int[] arr = birthday(pop_size);
    int count = 0;
    for(int i = 0; i < pop_size; i++){
      for(int j = i+1; j < pop_size; j++){
        if(arr[i] == arr[j]){
          return 1;
        }
      }
    }
    return count;
  }


  public static double prob(int pop_size, int num_sim){
    double count = 0.0;
    for(int i = 0; i < num_sim; i++){
      if(match(pop_size) == 1){
        count++;
      }
    }
    return count/num_sim;
  }
  
  public static void main(String[] args) {
    System.out.println(match(25));
    System.out.println(prob(23, 1000));
  }

}